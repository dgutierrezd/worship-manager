"use client";

import { useRouter } from "@/i18n/navigation";
import { useEffect } from "react";
import { getAccessToken } from "@/lib/api/client";
import { useAuthStore } from "@/lib/stores/auth-store";

/**
 * Client-side auth gate used inside the (app) segment. Redirects to
 * /login if no token or no hydrated profile exists. Renders nothing
 * while hydrating to avoid flicker.
 */
export function AuthGate({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const isHydrated = useAuthStore((s) => s.isHydrated);
  const profile = useAuthStore((s) => s.profile);

  useEffect(() => {
    if (!isHydrated) return;
    const token = getAccessToken();
    if (!token || !profile) {
      router.replace("/login");
    }
  }, [isHydrated, profile, router]);

  if (!isHydrated) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background">
        <div className="h-10 w-10 animate-spin rounded-full border-2 border-accent border-t-transparent" />
      </div>
    );
  }

  if (!profile || !getAccessToken()) return null;

  return <>{children}</>;
}
