"use client";
import { useTranslations } from "next-intl";
import { type FormEvent, useState } from "react";
import { AuthShell } from "@/components/auth-shell";
import { Enrol } from "@/components/enrol";
import { MfaChallenge } from "@/components/mfa";
import { Button, FormError, TextField } from "@/components/ui";
import { call, client, type Session, setCsrf } from "@/lib/api";

/** Only same-site paths: `next` comes from the URL and must not become an open redirect. */
function destination() {
  const next = new URLSearchParams(location.search).get("next") ?? "/";
  return /^\/(?![/\\])/.test(next) ? next : "/";
}

export default function LoginPage() {
  const t = useTranslations("login");
  const [session, setSession] = useState<Session | null>(null);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<unknown>(null);
  const done = () => location.assign(destination());

  async function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    setPending(true);
    setError(null);
    try {
      const result = await call(() =>
        client.POST("/api/v1/auth/login", {
          body: { email: String(form.get("email")), password: String(form.get("password")) },
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

  if (session?.stage === "mfa_enroll")
    return (
      <AuthShell title={t("enrolTitle")} lead={t("enrolLead")}>
        <Enrol onDone={done} />
      </AuthShell>
    );
  if (session)
    return (
      <AuthShell title={t("mfaTitle")} lead={t("mfaLead")}>
        <MfaChallenge methods={session.mfa_methods} onDone={done} />
      </AuthShell>
    );
  return (
    <AuthShell title={t("title")} lead={t("lead")}>
      <form onSubmit={submit} className="flex flex-col gap-4">
        <FormError error={error} />
        <TextField label={t("email")} name="email" type="email" autoComplete="username" required />
        <TextField
          label={t("password")}
          name="password"
          type="password"
          autoComplete="current-password"
          required
        />
        <Button type="submit" pending={pending}>
          {t("submit")}
        </Button>
      </form>
    </AuthShell>
  );
}
