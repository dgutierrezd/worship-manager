"use client";

import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import { clearSession, getAccessToken } from "@/lib/api/client";
import type { Profile } from "@/types";

interface AuthState {
  profile: Profile | null;
  isHydrated: boolean;
  setProfile: (profile: Profile | null) => void;
  setHydrated: () => void;
  signOut: () => void;
  isAuthenticated: () => boolean;
}

/**
 * Global auth store — persists the signed-in user's profile across page loads.
 * Token storage lives in the APIClient (localStorage) so the store stays
 * focused on UI-facing state.
 */
export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      profile: null,
      isHydrated: false,

      setProfile: (profile) => set({ profile }),
      setHydrated: () => set({ isHydrated: true }),

      signOut: () => {
        clearSession();
        set({ profile: null });
      },

      isAuthenticated: () => {
        // Presence of both token and profile = fully authenticated.
        return !!getAccessToken() && !!get().profile;
      },
    }),
    {
      name: "worshipflow_auth",
      storage: createJSONStorage(() => localStorage),
      partialize: (state) => ({ profile: state.profile }),
      onRehydrateStorage: () => (state) => {
        state?.setHydrated();
      },
    },
  ),
);
