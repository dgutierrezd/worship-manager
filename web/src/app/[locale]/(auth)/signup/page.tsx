"use client";

import { useTranslations } from "next-intl";
import { useState, type FormEvent } from "react";
import { Link, useRouter } from "@/i18n/navigation";
import { authApi } from "@/lib/api/auth";
import { useAuthStore } from "@/lib/stores/auth-store";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { errorMessage } from "@/lib/utils";

// Instrument values stay in English in the DB; labels are translated at render time.
const INSTRUMENT_VALUES = [
  "Vocals",
  "Guitar",
  "Bass",
  "Drums",
  "Keys",
  "Piano",
  "Other",
] as const;

const INSTRUMENT_I18N_KEYS: Record<(typeof INSTRUMENT_VALUES)[number], string> =
  {
    Vocals: "vocals",
    Guitar: "guitar",
    Bass: "bass",
    Drums: "drums",
    Keys: "keys",
    Piano: "piano",
    Other: "other",
  };

export default function SignUpPage() {
  const t = useTranslations("signup");
  const router = useRouter();
  const setProfile = useAuthStore((s) => s.setProfile);

  const [form, setForm] = useState({
    full_name: "",
    email: "",
    password: "",
    instrument: "",
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const update =
    (key: keyof typeof form) =>
    (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) =>
      setForm((prev) => ({ ...prev, [key]: e.target.value }));

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const { user } = await authApi.signUp({
        ...form,
        instrument: form.instrument || undefined,
      });
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
            name="full_name"
            type="text"
            label={t("fullName")}
            autoComplete="name"
            required
            value={form.full_name}
            onChange={update("full_name")}
          />
          <Input
            name="email"
            type="email"
            label={t("email")}
            autoComplete="email"
            required
            value={form.email}
            onChange={update("email")}
          />
          <Input
            name="password"
            type="password"
            label={t("password")}
            autoComplete="new-password"
            minLength={6}
            required
            value={form.password}
            onChange={update("password")}
          />

          <div className="flex flex-col">
            <label htmlFor="instrument" className="label">
              {t("instrumentLabel")}
            </label>
            <select
              id="instrument"
              name="instrument"
              value={form.instrument}
              onChange={update("instrument")}
              className="input"
            >
              <option value="">{t("instrumentPlaceholder")}</option>
              {INSTRUMENT_VALUES.map((inst) => (
                <option key={inst} value={inst}>
                  {t(`instruments.${INSTRUMENT_I18N_KEYS[inst]}`)}
                </option>
              ))}
            </select>
          </div>

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
          {t("haveAccount")}{" "}
          <Link
            href="/login"
            className="font-semibold text-accent hover:underline"
          >
            {t("signIn")}
          </Link>
        </p>
      </div>
    </div>
  );
}
