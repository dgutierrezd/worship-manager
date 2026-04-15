"use client";

import { useTranslations } from "next-intl";
import { useState, type FormEvent } from "react";
import { Link, useRouter } from "@/i18n/navigation";
import { authApi } from "@/lib/api/auth";
import { useAuthStore } from "@/lib/stores/auth-store";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { errorMessage } from "@/lib/utils";

export default function LoginPage() {
  const t = useTranslations("login");
  const router = useRouter();
  const setProfile = useAuthStore((s) => s.setProfile);

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const { user } = await authApi.signIn({ email, password });
      setProfile(user);
      router.replace("/home");
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="relative z-10 w-full max-w-md animate-fade-in">
      <div className="rounded-3xl border border-white/10 bg-white/95 p-8 shadow-elevated backdrop-blur">
        <div className="mb-8 text-center">
          <h1 className="font-display text-3xl font-semibold text-primary">
            {t("title")}
          </h1>
          <p className="mt-1 text-sm text-secondary">{t("subtitle")}</p>
        </div>

        <form onSubmit={onSubmit} className="space-y-4">
          <Input
            name="email"
            type="email"
            label={t("email")}
            autoComplete="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
          <Input
            name="password"
            type="password"
            label={t("password")}
            autoComplete="current-password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />

          {error && (
            <p className="rounded-xl border border-danger/30 bg-danger/10 px-4 py-3 text-sm text-danger">
              {error}
            </p>
          )}

          <Button
            type="submit"
            variant="accent"
            size="lg"
            fullWidth
            loading={loading}
          >
            {t("submit")}
          </Button>
        </form>

        <p className="mt-6 text-center text-sm text-secondary">
          {t("noAccount")}{" "}
          <Link
            href="/signup"
            className="font-semibold text-accent hover:underline"
          >
            {t("createOne")}
          </Link>
        </p>
      </div>
    </div>
  );
}
