"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import type { SongStem } from "@/types";

/**
 * Web Audio multitrack engine with sample-accurate sync, mute, solo,
 * and per-stem volume. Mirrors `MultitrackPlayerEngine.swift` on iOS.
 *
 * ## How it works
 * - Each stem URL is fetched once and decoded into an `AudioBuffer`
 * - All buffers play through a dedicated `GainNode` (one per stem) into
 *   `audioCtx.destination`, giving instant mute/solo/volume via `gain.value`
 * - Playback uses `AudioBufferSourceNode` scheduled at the same
 *   `audioCtx.currentTime + lead` for every stem → sample-accurate sync
 * - `AudioBufferSourceNode` is single-use (Web Audio spec), so pause/seek
 *   creates fresh source nodes and re-schedules them at a time offset
 *
 * ## CORS
 * Some cloud providers don't send `Access-Control-Allow-Origin` headers,
 * which makes `fetch` + `decodeAudioData` fail. Dropbox direct links, S3,
 * Cloudinary, Bunny, and most personal hosts work. Google Drive's
 * `uc?export=download` does NOT. If a stem fails to load, `loadError`
 * contains a helpful message naming the offending stem.
 */
export interface MultitrackEngineState {
  /** Stems currently bound to the engine. */
  stems: SongStem[];
  /** True while fetching + decoding. */
  isLoading: boolean;
  /** 0…1 progress across all stems. */
  loadingProgress: number;
  /** Non-null if one or more stems failed to decode. */
  loadError: string | null;
  /** True between `play()` and the end/pause/stop. */
  isPlaying: boolean;
  /** Longest stem's duration (sec). */
  duration: number;
  /** Current playhead (sec). */
  currentTime: number;
  /** Stem IDs that are currently muted. */
  muted: Set<string>;
  /** Stem IDs that are currently soloed. */
  soloed: Set<string>;
}

export interface MultitrackEngine extends MultitrackEngineState {
  play: () => void;
  pause: () => void;
  stop: () => void;
  seek: (time: number) => void;
  toggleMute: (stemId: string) => void;
  toggleSolo: (stemId: string) => void;
  setVolume: (stemId: string, volume: number) => void;
  getVolume: (stemId: string) => number;
}

interface Track {
  stem: SongStem;
  buffer: AudioBuffer;
  gain: GainNode;
  /** Active source node (recreated on play/seek because sources are one-shot). */
  source: AudioBufferSourceNode | null;
}

export function useMultitrackEngine(stems: SongStem[]): MultitrackEngine {
  const [isLoading, setIsLoading] = useState(false);
  const [loadingProgress, setLoadingProgress] = useState(0);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [duration, setDuration] = useState(0);
  const [currentTime, setCurrentTime] = useState(0);
  const [muted, setMutedState] = useState<Set<string>>(new Set());
  const [soloed, setSoloedState] = useState<Set<string>>(new Set());
  const [, forceRerender] = useState(0);

  // Cache-key for re-running the load effect when the set of stems changes
  const stemIds = stems.map((s) => s.id).join(",");

  const audioCtxRef = useRef<AudioContext | null>(null);
  const tracksRef = useRef<Map<string, Track>>(new Map());
  const volumesRef = useRef<Map<string, number>>(new Map());
  /** The audioCtx.currentTime at which playback (re)started. */
  const startContextTimeRef = useRef<number>(0);
  /** The seek offset used for the last `play()` call. */
  const startOffsetRef = useRef<number>(0);
  const rafRef = useRef<number | null>(null);

  // ---------- Load ----------

  useEffect(() => {
    let cancelled = false;

    async function load() {
      setLoadError(null);
      setLoadingProgress(0);

      if (stems.length === 0) {
        teardown();
        setDuration(0);
        setCurrentTime(0);
        return;
      }

      setIsLoading(true);

      // Lazily create the AudioContext (must be in a browser)
      if (!audioCtxRef.current) {
        try {
          const Ctx: typeof AudioContext =
            window.AudioContext ||
            (window as unknown as { webkitAudioContext: typeof AudioContext })
              .webkitAudioContext;
          audioCtxRef.current = new Ctx();
        } catch {
          setLoadError("Your browser does not support the Web Audio API.");
          setIsLoading(false);
          return;
        }
      }
      const ctx = audioCtxRef.current;

      // Tear down any previous graph (but keep the AudioContext)
      for (const t of tracksRef.current.values()) {
        try {
          t.source?.stop();
        } catch {}
        try {
          t.gain.disconnect();
        } catch {}
      }
      tracksRef.current.clear();

      try {
        let done = 0;
        const results = await Promise.all(
          stems.map(async (stem) => {
            const buf = await fetchAndDecode(stem, ctx);
            done += 1;
            if (!cancelled) setLoadingProgress(done / stems.length);
            return { stem, buffer: buf };
          }),
        );

        if (cancelled) return;

        // Wire up a fresh graph
        let maxDuration = 0;
        for (const { stem, buffer } of results) {
          const gain = ctx.createGain();
          gain.gain.value = volumesRef.current.get(stem.id) ?? 1;
          gain.connect(ctx.destination);
          tracksRef.current.set(stem.id, {
            stem,
            buffer,
            gain,
            source: null,
          });
          if (!volumesRef.current.has(stem.id)) {
            volumesRef.current.set(stem.id, 1);
          }
          if (buffer.duration > maxDuration) maxDuration = buffer.duration;
        }

        setDuration(maxDuration);
        setCurrentTime(0);
        setIsPlaying(false);
        startOffsetRef.current = 0;
        applyMixerGains();
      } catch (err) {
        const stemName = (err as Error & { stemLabel?: string }).stemLabel;
        const base = err instanceof Error ? err.message : "Failed to load stem";
        setLoadError(stemName ? `${stemName}: ${base}` : base);
      } finally {
        if (!cancelled) setIsLoading(false);
      }
    }

    load();

    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [stemIds]);

  // Tear down on unmount
  useEffect(() => {
    return () => {
      teardown();
      if (audioCtxRef.current) {
        try {
          audioCtxRef.current.close();
        } catch {}
        audioCtxRef.current = null;
      }
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ---------- Playback ----------

  const play = useCallback(() => {
    const ctx = audioCtxRef.current;
    if (!ctx) return;
    if (tracksRef.current.size === 0) return;
    if (isPlaying) return;

    // Resume suspended context (required for browser autoplay policy)
    if (ctx.state === "suspended") {
      void ctx.resume();
    }

    // Schedule every source for the same future time
    const lead = 0.08; // 80ms lead to avoid glitches
    const startAt = ctx.currentTime + lead;
    const offset = startOffsetRef.current;

    for (const track of tracksRef.current.values()) {
      const source = ctx.createBufferSource();
      source.buffer = track.buffer;
      source.connect(track.gain);

      const stemOffset = Math.min(offset, track.buffer.duration);
      if (stemOffset >= track.buffer.duration) {
        // This stem is already past its end — skip
        continue;
      }
      try {
        source.start(startAt, stemOffset);
      } catch {
        // `start` throws if the offset is out of range; silently skip
        continue;
      }
      track.source = source;
    }

    startContextTimeRef.current = startAt;
    setIsPlaying(true);
    startRafClock();
  }, [isPlaying]);

  const pause = useCallback(() => {
    const ctx = audioCtxRef.current;
    if (!ctx || !isPlaying) return;

    const elapsed = Math.max(0, ctx.currentTime - startContextTimeRef.current);
    const newOffset = Math.min(startOffsetRef.current + elapsed, duration);

    for (const track of tracksRef.current.values()) {
      try {
        track.source?.stop();
      } catch {}
      track.source = null;
    }

    startOffsetRef.current = newOffset;
    setCurrentTime(newOffset);
    setIsPlaying(false);
    stopRafClock();
  }, [isPlaying, duration]);

  const stop = useCallback(() => {
    for (const track of tracksRef.current.values()) {
      try {
        track.source?.stop();
      } catch {}
      track.source = null;
    }
    startOffsetRef.current = 0;
    setCurrentTime(0);
    setIsPlaying(false);
    stopRafClock();
  }, []);

  const seek = useCallback(
    (time: number) => {
      const clamped = Math.max(0, Math.min(time, duration));
      const wasPlaying = isPlaying;
      // Stop all current sources
      for (const track of tracksRef.current.values()) {
        try {
          track.source?.stop();
        } catch {}
        track.source = null;
      }
      startOffsetRef.current = clamped;
      setCurrentTime(clamped);
      setIsPlaying(false);
      stopRafClock();
      if (wasPlaying) {
        // Defer to next tick so state settles
        setTimeout(() => play(), 0);
      }
    },
    [isPlaying, duration, play],
  );

  // ---------- Mute / Solo / Volume ----------

  const toggleMute = useCallback((stemId: string) => {
    setMutedState((prev) => {
      const next = new Set(prev);
      if (next.has(stemId)) next.delete(stemId);
      else next.add(stemId);
      return next;
    });
  }, []);

  const toggleSolo = useCallback((stemId: string) => {
    setSoloedState((prev) => {
      const next = new Set(prev);
      if (next.has(stemId)) next.delete(stemId);
      else next.add(stemId);
      return next;
    });
  }, []);

  const setVolume = useCallback((stemId: string, volume: number) => {
    const clamped = Math.max(0, Math.min(1, volume));
    volumesRef.current.set(stemId, clamped);
    // Trigger re-render so the slider's controlled value stays in sync
    forceRerender((n) => n + 1);
    applyMixerGains();
  }, []);

  const getVolume = useCallback((stemId: string) => {
    return volumesRef.current.get(stemId) ?? 1;
  }, []);

  // Re-apply gains any time mute/solo changes
  useEffect(() => {
    applyMixerGains();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [muted, soloed]);

  function applyMixerGains() {
    const hasSolo = soloed.size > 0;
    for (const [id, track] of tracksRef.current.entries()) {
      const userVol = volumesRef.current.get(id) ?? 1;
      const isMuted = muted.has(id);
      const isSoloed = soloed.has(id);

      let effective: number;
      if (hasSolo) {
        effective = isSoloed ? userVol : 0;
      } else {
        effective = isMuted ? 0 : userVol;
      }
      // Smooth the transition a touch to avoid pops
      const ctx = audioCtxRef.current;
      if (ctx) {
        track.gain.gain.setTargetAtTime(effective, ctx.currentTime, 0.01);
      } else {
        track.gain.gain.value = effective;
      }
    }
  }

  // ---------- Clock ----------

  function startRafClock() {
    stopRafClock();
    const tick = () => {
      const ctx = audioCtxRef.current;
      if (!ctx) return;
      const elapsed = Math.max(0, ctx.currentTime - startContextTimeRef.current);
      const t = startOffsetRef.current + elapsed;
      if (t >= duration - 0.01) {
        // Auto-stop at end
        stop();
        return;
      }
      setCurrentTime(t);
      rafRef.current = requestAnimationFrame(tick);
    };
    rafRef.current = requestAnimationFrame(tick);
  }

  function stopRafClock() {
    if (rafRef.current != null) {
      cancelAnimationFrame(rafRef.current);
      rafRef.current = null;
    }
  }

  // ---------- Teardown helper ----------

  function teardown() {
    stopRafClock();
    for (const track of tracksRef.current.values()) {
      try {
        track.source?.stop();
      } catch {}
      try {
        track.gain.disconnect();
      } catch {}
    }
    tracksRef.current.clear();
    setIsPlaying(false);
    setCurrentTime(0);
    startOffsetRef.current = 0;
  }

  return {
    stems,
    isLoading,
    loadingProgress,
    loadError,
    isPlaying,
    duration,
    currentTime,
    muted,
    soloed,
    play,
    pause,
    stop,
    seek,
    toggleMute,
    toggleSolo,
    setVolume,
    getVolume,
  };
}

// ---------- Helpers ----------

async function fetchAndDecode(
  stem: SongStem,
  ctx: AudioContext,
): Promise<AudioBuffer> {
  let res: Response;
  try {
    res = await fetch(stem.url, { mode: "cors", cache: "force-cache" });
  } catch (err) {
    const message =
      "Couldn't fetch the audio. The host may not allow cross-origin requests. " +
      "Try Dropbox (direct link), S3, or a CORS-enabled host.";
    const e = new Error(message) as Error & { stemLabel: string };
    e.stemLabel = stem.label;
    e.cause = err;
    throw e;
  }
  if (!res.ok) {
    const e = new Error(`HTTP ${res.status}`) as Error & { stemLabel: string };
    e.stemLabel = stem.label;
    throw e;
  }
  const arrayBuffer = await res.arrayBuffer();
  try {
    return await ctx.decodeAudioData(arrayBuffer);
  } catch (err) {
    const e = new Error(
      "Couldn't decode audio. Make sure the URL points to a real MP3, M4A, AAC, OGG, or WAV file.",
    ) as Error & { stemLabel: string };
    e.stemLabel = stem.label;
    e.cause = err;
    throw e;
  }
}
