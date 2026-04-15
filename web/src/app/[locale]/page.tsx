"use client";

import { useEffect } from "react";
import { useRouter } from "@/i18n/navigation";
import { getAccessToken } from "@/lib/api/client";
import { useAuthStore } from "@/lib/stores/auth-store";

/**
 * Root route. Redirects based on auth state once the auth store hydrates.
 */
export default function RootPage() {
  const router = useRouter();
  const isHydrated = useAuthStore((s) => s.isHydrated);
  const profile = useAuthStore((s) => s.profile);

  useEffect(() => {
    if (!isHydrated) return;
    if (profile && getAccessToken()) {
      router.replace("/home");
    } else {
      router.replace("/welcome");
    }
  }, [isHydrated, profile, router]);

  return (
    <div className="flex min-h-screen items-center justify-center bg-background">
      <div className="h-10 w-10 animate-spin rounded-full border-2 border-accent border-t-transparent" />
    </div>
  );
}
