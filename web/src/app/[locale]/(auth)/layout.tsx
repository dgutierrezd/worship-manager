import type { ReactNode } from "react";

/**
 * Unauthenticated shell. Aurora gradient backdrop + subtle grain so the
 * form/hero cards feel premium.
 */
export default function AuthLayout({ children }: { children: ReactNode }) {
  return (
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-sidebar px-6 py-10 text-sidebar-fg noise">
      {/* Ambient gradient blobs */}
      <div className="pointer-events-none absolute inset-0 -z-10">
        <div className="absolute left-1/2 top-0 h-[620px] w-[620px] -translate-x-1/2 rounded-full bg-accent/30 blur-3xl" />
        <div className="absolute -bottom-20 right-0 h-[420px] w-[420px] rounded-full bg-[rgb(14_165_233_/_0.22)] blur-3xl" />
        <div className="absolute -left-10 top-1/3 h-[360px] w-[360px] rounded-full bg-[rgb(99_102_241_/_0.18)] blur-3xl" />
      </div>

      {/* Faint grid overlay for extra depth */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 -z-10 opacity-[0.06]"
        style={{
          backgroundImage:
            "linear-gradient(to right, white 1px, transparent 1px), linear-gradient(to bottom, white 1px, transparent 1px)",
          backgroundSize: "48px 48px",
        }}
      />

      {children}
    </div>
  );
}
