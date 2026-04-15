import type { MetadataRoute } from "next";

/**
 * Web App Manifest — enables "Add to Home Screen" / install as a PWA.
 * Next.js serves this automatically at `/manifest.webmanifest`.
 */
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Worship Manager",
    short_name: "Worship",
    description:
      "Plan services, manage your song library, and coordinate your worship team.",
    start_url: "/",
    display: "standalone",
    background_color: "#0B1B3B",
    theme_color: "#0B1B3B",
    orientation: "portrait",
    icons: [
      {
        src: "/icon-192.png",
        sizes: "192x192",
        type: "image/png",
        purpose: "any",
      },
      {
        src: "/icon-512.png",
        sizes: "512x512",
        type: "image/png",
        purpose: "any",
      },
      {
        src: "/icon-512.png",
        sizes: "512x512",
        type: "image/png",
        purpose: "maskable",
      },
    ],
  };
}
