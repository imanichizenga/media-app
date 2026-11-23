"use client";
import { useTranslations } from "next-intl";
import { type FormEvent, useEffect, useState } from "react";
import { AuthShell } from "@/components/auth-shell";
import { Button, FormError, Notice, TextField } from "@/components/ui";
import { call, client } from "@/lib/api";
import { takeFragment } from "@/lib/fragment";

export default function ResetPage() {
  const t = useTranslations("reset");
  const [token, setToken] = useState("");
  const [done, setDone] = useState(false);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<unknown>(null);
  useEffect(() => setToken(takeFragment()), []);
  async function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const password = String(new FormData(e.currentTarget).get("password"));
    setPending(true);
    setError(null);
    try {
      await call(() => client.POST("/api/v1/auth/reset/complete", { body: { token, password } }));
      setDone(true);
    } catch (err) {
      setError(err);
    } finally {
      setPending(false);
    }
  }
  return (
    <AuthShell title={t("title")} lead={t("lead")}>
      {done ? (
        <div className="flex flex-col gap-4">
          <Notice tone="success">{t("done")}</Notice>
          <Button onClick={() => location.assign("/login")}>{t("signIn")}</Button>
        </div>
      ) : (
        <form onSubmit={submit} className="flex flex-col gap-4">
          <FormError error={error} />
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
      )}
    </AuthShell>
  );
}
