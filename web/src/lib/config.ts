/**
 * Application-wide configuration.
 * All environment variables prefixed with NEXT_PUBLIC_* are exposed to the browser.
 */
export const config = {
  // Relative path works in production (Next.js rewrites /api/* to the backend).
  // Override with NEXT_PUBLIC_API_BASE_URL in local dev if needed.
  apiBaseUrl: process.env.NEXT_PUBLIC_API_BASE_URL ?? "/api",
  storage: {
    accessTokenKey: "worshipflow_access_token",
    refreshTokenKey: "worshipflow_refresh_token",
    currentBandKey: "worshipflow_current_band",
  },
} as const;
