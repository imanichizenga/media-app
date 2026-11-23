"use client";
import { startRegistration } from "@simplewebauthn/browser";
import { Copy, KeyRound, Smartphone } from "lucide-react";
import { useTranslations } from "next-intl";
import { type FormEvent, useState } from "react";
import { ApiError, call, client, type Session, setCsrf } from "@/lib/api";
import { Button, FormError, Notice, TextField } from "./ui";

export function RecoveryCodes({ codes, onDone }: { codes: string[]; onDone: () => void }) {
  const t = useTranslations("mfa");
  const [copied, setCopied] = useState(false);
  return (
    <div className="flex flex-col gap-4">
      <Notice tone="warning">{t("recoveryWarning")}</Notice>
      <ul
        aria-label={t("recoveryTitle")}
        className="grid grid-cols-1 gap-2 rounded-sm bg-surface-sunken p-4 font-mono sm:grid-cols-2"
      >
        {codes.map((c) => (
          <li key={c} className="select-all">
            {c}
          </li>
        ))}
      </ul>
      <Button
        variant="secondary"
        onClick={() => navigator.clipboard.writeText(codes.join("\n")).then(() => setCopied(true))}
      >
        <Copy aria-hidden size={18} />
        {t(copied ? "copied" : "copyCodes")}
      </Button>
      <Button onClick={onDone}>{t("savedCodes")}</Button>
    </div>
  );
}

/** Sets up the first factor, or adds another. */
export function Enrol({
  onDone,
  allowTotp = true,
}: {
  onDone: (session: Session) => void;
  allowTotp?: boolean;
}) {
  const t = useTranslations("mfa");
  const [totp, setTotp] = useState<{ secret: string; qr_svg: string } | null>(null);
  const [codes, setCodes] = useState<string[] | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [code, setCode] = useState("");
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<unknown>(null);

  async function guard(action: () => Promise<void>) {
    setPending(true);
    setError(null);
    try {
      await action();
    } catch (e) {
      setError(e instanceof ApiError ? e : new ApiError(0, "passkey_cancelled", ""));
    } finally {
      setPending(false);
    }
  }
  function finish(result: { session: Session; recovery_codes: string[] }) {
    setCsrf(result.session.csrf_token);
    if (!result.recovery_codes.length) return onDone(result.session);
    setSession(result.session);
    setCodes(result.recovery_codes);
  }
  const passkey = () =>
    guard(async () => {
      const options = await call(() => client.POST("/api/v1/auth/mfa/passkey/register/options"));
      const credential = await startRegistration({ optionsJSON: options as never });
      const name = /Mac|iPhone|iPad/.test(navigator.userAgent)
        ? "Apple"
        : /Android/.test(navigator.userAgent)
          ? "Android"
          : "Passkey";
      finish(
        await call(() =>
          client.POST("/api/v1/auth/mfa/passkey/register", { body: { credential: { ...credential }, name } }),
        ),
      );
    });
  const begin = () =>
    guard(async () => setTotp(await call(() => client.POST("/api/v1/auth/mfa/totp/begin"))));
  const confirm = (e: FormEvent) => {
    e.preventDefault();
    guard(async () =>
      finish(await call(() => client.POST("/api/v1/auth/mfa/totp/confirm", { body: { code } }))),
    );
  };

  if (codes && session) return <RecoveryCodes codes={codes} onDone={() => onDone(session)} />;
  return (
    <div className="flex flex-col gap-4">
      <FormError error={error} />
      {totp ? (
        <form onSubmit={confirm} className="flex flex-col gap-4">
          <p>{t("scan")}</p>
          {/* biome-ignore lint/performance/noImgElement: a data: QR code has nothing to optimise */}
          <img
            alt={t("qrAlt")}
            src={`data:image/svg+xml;base64,${totp.qr_svg}`}
            width={200}
            height={200}
            className="self-center rounded-sm bg-white"
          />
          <p className="text-caption break-all text-text-secondary">
            {t("manual")} <code className="font-mono select-all">{totp.secret}</code>
          </p>
          <TextField
            label={t("totpCode")}
            value={code}
            onChange={(e) => setCode(e.target.value)}
            inputMode="numeric"
            autoComplete="one-time-code"
            maxLength={6}
            required
          />
          <Button type="submit" pending={pending}>
            {t("verify")}
          </Button>
        </form>
      ) : (
        <>
          <Button onClick={passkey} pending={pending}>
            <KeyRound aria-hidden size={18} />
            {t("createPasskey")}
          </Button>
          {allowTotp && (
            <Button variant="secondary" onClick={begin} disabled={pending}>
              <Smartphone aria-hidden size={18} />
              {t("useApp")}
            </Button>
          )}
        </>
      )}
    </div>
  );
}
