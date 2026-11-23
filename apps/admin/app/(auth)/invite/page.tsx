"use client";
import { useLocale, useTranslations } from "next-intl";
import { type FormEvent, useEffect, useState } from "react";
import { AuthShell } from "@/components/auth-shell";
import { Enrol } from "@/components/enrol";
import { Button, FormError, TextField } from "@/components/ui";
import { ApiError, call, client, type Session, setCsrf } from "@/lib/api";
import { takeFragment } from "@/lib/fragment";

export default function InvitePage() {
  const t = useTranslations("invite");
  const locale = useLocale();
  const [token, setToken] = useState("");
  const [session, setSession] = useState<Session | null>(null);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<unknown>(null);
  useEffect(() => setToken(takeFragment()), []);

  async function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    setPending(true);
    setError(null);
    try {
      const result = await call(() =>
        client.POST("/api/v1/auth/invite/accept", {
          body: {
            token,
            display_name: String(form.get("name")),
            password: String(form.get("password")),
            locale: locale === "en" ? "en" : "sw",
          },
        }),
      );
      setCsrf(result.csrf_token);
      setSession(result);
    } catch (err) {
      setError(err);
    } finally {
      setPending(false);
    }
  }
  const fields = error instanceof ApiError ? error.fields : {};
  if (session?.stage === "mfa_challenge") location.assign("/login");
  if (session)
    return (
      <AuthShell title={t("enrolTitle")} lead={t("enrolLead")}>
        <Enrol onDone={() => location.assign("/")} />
      </AuthShell>
    );
  return (
    <AuthShell title={t("title")} lead={t("lead")}>
      <form onSubmit={submit} className="flex flex-col gap-4">
        <FormError error={error} />
        <TextField
          label={t("name")}
          name="name"
          autoComplete="name"
          maxLength={80}
          required
          error={fields.display_name}
        />
        <TextField
          label={t("password")}
          help={t("passwordHelp")}
          name="password"
          type="password"
          autoComplete="new-password"
          minLength={12}
          required
        />
        <Button type="submit" pending={pending}>
          {t("submit")}
        </Button>
      </form>
    </AuthShell>
  );
}
