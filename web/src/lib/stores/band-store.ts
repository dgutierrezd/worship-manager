"use client";

import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import type { Band } from "@/types";

interface BandState {
  currentBand: Band | null;
  setCurrentBand: (band: Band | null) => void;
}

/**
 * `currentBand` mirrors `BandViewModel.currentBand` on iOS — single source of
 * truth for the active band across the app.
 */
export const useBandStore = create<BandState>()(
  persist(
    (set) => ({
      currentBand: null,
      setCurrentBand: (band) => set({ currentBand: band }),
    }),
    {
      name: "worshipflow_band",
      storage: createJSONStorage(() => localStorage),
    },
  ),
);
