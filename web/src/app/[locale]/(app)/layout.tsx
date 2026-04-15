import type { ReactNode } from "react";
import { AuthGate } from "@/components/layout/auth-gate";
import { BandRequired } from "@/components/layout/band-required";
import { Sidebar } from "@/components/layout/sidebar";

/**
 * The authenticated shell. Sidebar navigation + main content region.
 * All routes underneath `(app)/*` require a valid session and at least
 * one band.
 */
export default function AppLayout({ children }: { children: ReactNode }) {
  return (
    <AuthGate>
      <div className="flex min-h-screen bg-background">
        <Sidebar />
        <main className="flex-1 overflow-x-hidden">
          <BandRequired>
            <div className="mx-auto w-full max-w-6xl px-6 py-10 md:px-10">
              {children}
            </div>
          </BandRequired>
        </main>
      </div>
    </AuthGate>
  );
}
