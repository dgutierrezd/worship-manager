import type { Config } from "tailwindcss";

// Design tokens live as CSS variables in `globals.css` so they compose with
// rgb(... / <alpha>) for arbitrary opacity. Tailwind only exposes them here.
const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        background: "rgb(var(--app-background) / <alpha-value>)",
        surface: "rgb(var(--app-surface) / <alpha-value>)",
        surfaceMuted: "rgb(var(--app-surface-muted) / <alpha-value>)",
        primary: "rgb(var(--app-primary) / <alpha-value>)",
        secondary: "rgb(var(--app-secondary) / <alpha-value>)",
        divider: "rgb(var(--app-divider) / <alpha-value>)",
        accent: "rgb(var(--app-accent) / <alpha-value>)",
        accentStrong: "rgb(var(--app-accent-strong) / <alpha-value>)",
        accentMuted: "rgb(var(--app-accent-muted) / <alpha-value>)",
        success: "rgb(var(--app-success) / <alpha-value>)",
        warning: "rgb(var(--app-warning) / <alpha-value>)",
        danger: "rgb(var(--app-danger) / <alpha-value>)",
        going: "rgb(var(--app-going) / <alpha-value>)",
        maybe: "rgb(var(--app-maybe) / <alpha-value>)",
        no: "rgb(var(--app-no) / <alpha-value>)",
        sidebar: {
          DEFAULT: "rgb(var(--app-sidebar-bg) / <alpha-value>)",
          panel: "rgb(var(--app-sidebar-bg-2) / <alpha-value>)",
          fg: "rgb(var(--app-sidebar-fg) / <alpha-value>)",
          muted: "rgb(var(--app-sidebar-muted) / <alpha-value>)",
          divider: "rgb(var(--app-sidebar-divider) / <alpha-value>)",
        },
      },
      fontFamily: {
        sans: ["var(--font-sans)", "system-ui", "sans-serif"],
        display: ["var(--font-display)", "system-ui", "sans-serif"],
        mono: ["var(--font-mono)", "monospace"],
      },
      borderRadius: {
        xl: "0.875rem",
        "2xl": "1.125rem",
        "3xl": "1.5rem",
      },
      boxShadow: {
        // Softer, bluer shadows that sit well on a cool background
        card: "0 1px 2px rgb(11 27 59 / 0.04), 0 4px 16px -6px rgb(11 27 59 / 0.06)",
        elevated:
          "0 12px 32px -12px rgb(11 27 59 / 0.18), 0 4px 12px -4px rgb(11 27 59 / 0.08)",
        glow: "0 0 0 3px rgb(37 99 235 / 0.2)",
        accentGlow: "0 10px 30px -10px rgb(37 99 235 / 0.45)",
      },
      backgroundImage: {
        "hero-aurora":
          "radial-gradient(1000px 600px at 10% -10%, rgb(37 99 235 / 0.25), transparent 60%), radial-gradient(800px 500px at 90% 110%, rgb(14 165 233 / 0.18), transparent 60%)",
        "sidebar-gradient":
          "linear-gradient(180deg, rgb(var(--app-sidebar-bg)) 0%, rgb(var(--app-sidebar-bg-2)) 100%)",
      },
      keyframes: {
        "fade-in": {
          from: { opacity: "0", transform: "translateY(6px)" },
          to: { opacity: "1", transform: "translateY(0)" },
        },
        "fade-in-fast": {
          from: { opacity: "0" },
          to: { opacity: "1" },
        },
        shimmer: {
          "0%": { backgroundPosition: "-200% 0" },
          "100%": { backgroundPosition: "200% 0" },
        },
        float: {
          "0%, 100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-6px)" },
        },
      },
      animation: {
        "fade-in": "fade-in 0.35s cubic-bezier(0.22, 1, 0.36, 1)",
        "fade-in-fast": "fade-in-fast 0.15s ease-out",
        shimmer: "shimmer 1.6s linear infinite",
        float: "float 6s ease-in-out infinite",
      },
    },
  },
  plugins: [],
};

export default config;
