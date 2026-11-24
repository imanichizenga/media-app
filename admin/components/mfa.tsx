"use client";
import { startAuthentication } from "@simplewebauthn/browser";
import { KeyRound, LifeBuoy, Smartphone } from "lucide-react";
import { useTranslations } from "next-intl";
import { type FormEvent, useState } from "react";
import { ApiError, call, client, type Session, setCsrf } from "@/lib/api";
import { Button, FormError, TextField } from "./ui";

type Method = "passkey" | "totp" | "recovery";
const ICONS = { passkey: KeyRound, totp: Smartphone, recovery: LifeBuoy };

/** The second step, shared by sign-in and step-up. */
export function MfaChallenge({ methods, onDone }: { methods: string[]; onDone: (session: Session) => void }) {
  const t = useTranslations("mfa");
  const available = (["passkey", "totp", "recovery"] as const).filter((m) => methods.includes(m));
  const [method, setMethod] = useState<Method>(available[0] ?? "totp");
  const [code, setCode] = useState("");
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<unknown>(null);

  async function run(action: () => Promise<Session>) {
    setPending(true);
    setError(null);
    try {
      const session = await action();
      setCsrf(session.csrf_token);
      onDone(session);
    } catch (e) {
      setError(e instanceof ApiError ? e : new ApiError(0, "passkey_cancelled", ""));
      setCode("");
    } finally {
      setPending(false);
    }
  }
  const passkey = () =>
    run(async () => {
      const options = await call(() => client.POST("/api/v1/auth/mfa/passkey/options"));
      const credential = await startAuthentication({ optionsJSON: options as never });
      return call(() =>
        client.POST("/api/v1/auth/mfa/passkey/verify", { body: { credential: { ...credential }, name: "" } }),
      );
    });
  const submit = (e: FormEvent) => {
    e.preventDefault();
    const path = method === "totp" ? "/api/v1/auth/mfa/totp/verify" : "/api/v1/auth/mfa/recovery/verify";
    run(() => call(() => client.POST(path, { body: { code } })));
  };

  return (
    <div className="flex flex-col gap-4">
      <FormError error={error} />
      {method === "passkey" ? (
        <Button onClick={passkey} pending={pending} className="w-full">
          <KeyRound aria-hidden size={18} />
          {t("usePasskey")}
        </Button>
      ) : (
        <form onSubmit={submit} className="flex flex-col gap-4">
          <TextField
            key={method}
            label={t(method === "totp" ? "totpCode" : "recoveryCode")}
            value={code}
            onChange={(e) => setCode(e.target.value)}
            inputMode={method === "totp" ? "numeric" : "text"}
            autoComplete="one-time-code"
            maxLength={method === "totp" ? 6 : 16}
            required
            autoFocus
          />
          <Button type="submit" pending={pending}>
            {t("verify")}
          </Button>
        </form>
      )}
      <div className="flex flex-col">
        {available
          .filter((m) => m !== method)
          .map((m) => {
            const Icon = ICONS[m];
            return (
              <Button
                key={m}
                variant="ghost"
                onClick={() => {
                  setMethod(m);
                  setError(null);
                  setCode("");
                }}
              >
                <Icon aria-hidden size={18} />
                {t(`switch.${m}`)}
              </Button>
            );
          })}
      </div>
    </div>
  );
}
