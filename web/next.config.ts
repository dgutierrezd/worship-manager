import type { NextConfig } from "next";
import createNextIntlPlugin from "next-intl/plugin";

const withNextIntl = createNextIntlPlugin("./src/i18n/request.ts");

const nextConfig: NextConfig = {
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
