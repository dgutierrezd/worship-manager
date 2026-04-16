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
    // BACKEND_INTERNAL_URL overrides in local dev (http://localhost:3000).
    // Falls back to the production backend Vercel project.
    const backend = process.env.BACKEND_INTERNAL_URL ?? "https://worship-manager-psi.vercel.app";
    return [
      {
        source: "/api/:path*",
        destination: `${backend}/api/:path*`,
      },
    ];
  },
};

export default withNextIntl(nextConfig);
