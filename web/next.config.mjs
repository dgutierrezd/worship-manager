import createNextIntlPlugin from "next-intl/plugin";

// No explicit path — next-intl auto-discovers ./i18n/request.ts (project root).
// Avoids webpack fsPath resolution failures in Vercel's build environment.
const withNextIntl = createNextIntlPlugin();

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "isctjrimtuocjfgfrjyo.supabase.co",
      },
    ],
  },
  async rewrites() {
    // In production this env var points to the backend Vercel project URL.
    // In local dev it points to the Express server running on port 3000.
    const backend = process.env.BACKEND_INTERNAL_URL ?? "http://localhost:3000";
    return [
      {
        source: "/api/:path*",
        destination: `${backend}/api/:path*`,
      },
    ];
  },
};

export default withNextIntl(nextConfig);
