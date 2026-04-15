/**
 * Application-wide configuration.
 * All environment variables prefixed with NEXT_PUBLIC_* are exposed to the browser.
 */
export const config = {
  apiBaseUrl:
    process.env.NEXT_PUBLIC_API_BASE_URL ??
    "https://worship-manager-psi.vercel.app/api",
  storage: {
    accessTokenKey: "worshipflow_access_token",
    refreshTokenKey: "worshipflow_refresh_token",
    currentBandKey: "worshipflow_current_band",
  },
} as const;
