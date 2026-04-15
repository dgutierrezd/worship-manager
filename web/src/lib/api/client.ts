import { config } from "@/lib/config";
import type { AuthSession } from "@/types";

/**
 * APIClient — a small `fetch` wrapper that mirrors the iOS `APIClient` actor.
 *
 * Responsibilities:
 * - Attach Bearer tokens from localStorage
 * - Parse JSON responses and throw structured errors
 * - Automatically silently refresh on 401 once before failing
 *
 * The client is safe for both server and browser contexts. Token storage only
 * happens in the browser (localStorage is guarded behind `typeof window`).
 */

export class ApiError extends Error {
  readonly status: number;
  readonly payload: unknown;

  constructor(message: string, status: number, payload: unknown) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.payload = payload;
  }
}

type HttpMethod = "GET" | "POST" | "PUT" | "PATCH" | "DELETE";

interface RequestOptions {
  method?: HttpMethod;
  body?: unknown;
  /** Skip auth header (used by signin/signup endpoints). */
  skipAuth?: boolean;
  /** Prevent infinite refresh loops. */
  _retry?: boolean;
  /** Allow custom headers (e.g. multipart). */
  headers?: Record<string, string>;
  /** Signal for request cancellation. */
  signal?: AbortSignal;
}

/* --------------------------- token persistence --------------------------- */

function isBrowser(): boolean {
  return typeof window !== "undefined";
}

export function getAccessToken(): string | null {
  if (!isBrowser()) return null;
  return localStorage.getItem(config.storage.accessTokenKey);
}

export function getRefreshToken(): string | null {
  if (!isBrowser()) return null;
  return localStorage.getItem(config.storage.refreshTokenKey);
}

export function setSession(session: AuthSession): void {
  if (!isBrowser()) return;
  localStorage.setItem(config.storage.accessTokenKey, session.access_token);
  localStorage.setItem(config.storage.refreshTokenKey, session.refresh_token);
}

export function clearSession(): void {
  if (!isBrowser()) return;
  localStorage.removeItem(config.storage.accessTokenKey);
  localStorage.removeItem(config.storage.refreshTokenKey);
}

/* ------------------------------ core request ----------------------------- */

async function refreshAccessToken(): Promise<boolean> {
  const refresh = getRefreshToken();
  if (!refresh) return false;

  try {
    const res = await fetch(`${config.apiBaseUrl}/auth/refresh`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refresh_token: refresh }),
    });

    if (!res.ok) {
      clearSession();
      return false;
    }

    const data = (await res.json()) as { session: AuthSession };
    setSession(data.session);
    return true;
  } catch {
    clearSession();
    return false;
  }
}

async function request<T>(path: string, opts: RequestOptions = {}): Promise<T> {
  const {
    method = "GET",
    body,
    skipAuth = false,
    _retry = false,
    headers = {},
    signal,
  } = opts;

  const url = `${config.apiBaseUrl}${path}`;
  const finalHeaders: Record<string, string> = { ...headers };

  if (body !== undefined && !(body instanceof FormData)) {
    finalHeaders["Content-Type"] = "application/json";
  }

  if (!skipAuth) {
    const token = getAccessToken();
    if (token) finalHeaders.Authorization = `Bearer ${token}`;
  }

  const res = await fetch(url, {
    method,
    headers: finalHeaders,
    body:
      body === undefined
        ? undefined
        : body instanceof FormData
          ? body
          : JSON.stringify(body),
    cache: "no-store",
    signal,
  });

  // Auto-refresh on 401 (once)
  if (res.status === 401 && !skipAuth && !_retry) {
    const refreshed = await refreshAccessToken();
    if (refreshed) {
      return request<T>(path, { ...opts, _retry: true });
    }
  }

  // Empty body (204 etc.)
  if (res.status === 204) {
    return undefined as T;
  }

  let payload: unknown = null;
  const text = await res.text();
  if (text) {
    try {
      payload = JSON.parse(text);
    } catch {
      payload = text;
    }
  }

  if (!res.ok) {
    const message =
      (payload && typeof payload === "object" && "error" in payload
        ? String((payload as { error: unknown }).error)
        : res.statusText) || `Request failed (${res.status})`;
    throw new ApiError(message, res.status, payload);
  }

  return payload as T;
}

/* ------------------------------ public API ------------------------------- */

export const apiClient = {
  get: <T>(path: string, opts: Omit<RequestOptions, "method" | "body"> = {}) =>
    request<T>(path, { ...opts, method: "GET" }),

  post: <T>(path: string, body?: unknown, opts: Omit<RequestOptions, "method" | "body"> = {}) =>
    request<T>(path, { ...opts, method: "POST", body }),

  put: <T>(path: string, body?: unknown, opts: Omit<RequestOptions, "method" | "body"> = {}) =>
    request<T>(path, { ...opts, method: "PUT", body }),

  patch: <T>(path: string, body?: unknown, opts: Omit<RequestOptions, "method" | "body"> = {}) =>
    request<T>(path, { ...opts, method: "PATCH", body }),

  delete: <T = void>(path: string, opts: Omit<RequestOptions, "method" | "body"> = {}) =>
    request<T>(path, { ...opts, method: "DELETE" }),
};
