import { apiClient, clearSession, setSession } from "@/lib/api/client";
import type { AuthResponse, Profile } from "@/types";

export interface SignUpInput {
  email: string;
  password: string;
  full_name: string;
  instrument?: string;
}

export interface SignInInput {
  email: string;
  password: string;
}

export const authApi = {
  async signUp(input: SignUpInput): Promise<AuthResponse> {
    const res = await apiClient.post<AuthResponse>("/auth/signup", input, {
      skipAuth: true,
    });
    setSession(res.session);
    return res;
  },

  async signIn(input: SignInInput): Promise<AuthResponse> {
    const res = await apiClient.post<AuthResponse>("/auth/signin", input, {
      skipAuth: true,
    });
    setSession(res.session);
    return res;
  },

  async signOut(): Promise<void> {
    try {
      await apiClient.post("/auth/signout");
    } finally {
      clearSession();
    }
  },

  /**
   * There is no dedicated /me endpoint server-side — cold-start profile
   * hydration happens by re-reading the local profile cache in the Zustand
   * store, and the presence of a valid token is sufficient.
   */
  async getProfileFromBands(): Promise<Profile | null> {
    // Placeholder for future /me route; returns null today.
    return null;
  },
};
