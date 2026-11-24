"use client";
import { useQueryClient } from "@tanstack/react-query";
import { useTranslations } from "next-intl";
import { type FormEvent, useState } from "react";
import { Enrol, RecoveryCodes } from "@/components/enrol";
import {
  Badge,
  Bone,
  Button,
  Card,
  Dialog,
  ErrorState,
  FormError,
  Notice,
  PageHeader,
  TextField,
} from "@/components/ui";
import { call, client } from "@/lib/api";
import { keys, useMySecurity, useTime } from "@/lib/queries";

const ROW = "flex min-h-14 flex-wrap items-center justify-between gap-2 py-2";
const Bones = ({ n }: { n: number }) =>
  Array.from({ length: n }, (_, i) => (
    // biome-ignore lint/suspicious/noArrayIndexKey: static placeholders
    <li key={i} className={ROW} data-skeleton="row">
      <Bone className="w-48" />
      <Bone className="w-20" />
    </li>
  ));
export default function Security() {
  const t = useTranslations("security");
  const time = useTime();
  const queries = useQueryClient();
  const { data, error, refetch } = useMySecurity();
  const [adding, setAdding] = useState(false);
  const [codes, setCodes] = useState<string[] | null>(null);
  const [pending, setPending] = useState("");
  const [problem, setProblem] = useState<unknown>(null);
  const [notice, setNotice] = useState("");
  if (error && !data) return <ErrorState error={error} retry={refetch} />;
  const refresh = () =>
    Promise.all([
      queries.invalidateQueries({ queryKey: keys.security }),
      queries.invalidateQueries({ queryKey: keys.session }),
    ]);
  async function act(name: string, fn: () => Promise<unknown>, message = "") {
    setPending(name);
    setProblem(null);
    setNotice("");
    try {
      await fn();
      setNotice(message);
      await refresh();
    } catch (e) {
      setProblem(e);
    } finally {
      setPending("");
    }
  }
  const removeFactor = (factor: string) =>
    act(factor, () =>
      call(() => client.DELETE("/api/v1/me/factors/{factor}", { params: { path: { factor } } })),
    );
  function password(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formEl = e.currentTarget;
    const form = new FormData(formEl);
    act(
      "password",
      async () => {
        await call(() =>
          client.POST("/api/v1/me/password", {
            body: { current: String(form.get("current")), new: String(form.get("new")) },
          }),
        );
        formEl.reset();
      },
      t("passwordChanged"),
    );
  }
  return (
    <>
      <PageHeader title={t("title")} lead={t("lead")} />
      <div className="mb-4 flex flex-col gap-3 empty:hidden">
        <FormError error={problem} />
        {notice && <Notice tone="success">{notice}</Notice>}
      </div>
      <div className="grid items-start gap-4 md:grid-cols-2">
        <Card>
          <h2 className="text-headline-s">{t("factors")}</h2>
          <ul className="my-3 divide-y divide-border">
            {!data && <Bones n={2} />}
            {data?.passkeys.map((p) => (
              <li key={p.id} className={ROW}>
                <span>
                  {p.name}{" "}
                  <span className="text-caption text-text-secondary">
                    · {t("lastUsed")} {time(p.last_used_at)}
                  </span>
                </span>
                <Button variant="ghost" pending={pending === p.id} onClick={() => removeFactor(p.id)}>
                  {t("remove")}
                </Button>
              </li>
            ))}
            {data?.totp && (
              <li className={ROW}>
                <span>{t("app")}</span>
                <Button variant="ghost" pending={pending === "totp"} onClick={() => removeFactor("totp")}>
                  {t("remove")}
                </Button>
              </li>
            )}
            {data && (
              <li className={ROW}>
                <span>{t("codesLeft", { count: data.recovery_codes_left })}</span>
                <Button
                  variant="ghost"
                  pending={pending === "codes"}
                  onClick={() =>
                    act("codes", async () =>
                      setCodes((await call(() => client.POST("/api/v1/me/recovery-codes"))).recovery_codes),
                    )
                  }
                >
                  {t("newCodes")}
                </Button>
              </li>
            )}
          </ul>
          <Button variant="secondary" onClick={() => setAdding(true)}>
            {t("add")}
          </Button>
        </Card>
        <Card>
          <h2 className="text-headline-s">{t("password")}</h2>
          <form onSubmit={password} className="mt-3 flex flex-col gap-4">
            <TextField
              label={t("currentPassword")}
              name="current"
              type="password"
              autoComplete="current-password"
              required
            />
            <TextField
              label={t("newPassword")}
              help={t("passwordHelp")}
              name="new"
              type="password"
              autoComplete="new-password"
              minLength={12}
              required
            />
            <Button type="submit" variant="secondary" pending={pending === "password"}>
              {t("changePassword")}
            </Button>
          </form>
        </Card>
        <Card className="md:col-span-2">
          <h2 className="text-headline-s">{t("sessions")}</h2>
          <ul className="mt-3 divide-y divide-border">
            {data?.sessions.map((s) => (
              <li key={s.id} className={ROW}>
                <span>
                  {s.device_label}{" "}
                  <span className="text-caption text-text-secondary">
                    · {s.ip} {s.country} · {time(s.last_seen_at)}
                  </span>
                </span>
                {s.current ? (
                  <Badge tone="success">{t("thisDevice")}</Badge>
                ) : (
                  <Button
                    variant="ghost"
                    pending={pending === s.id}
                    onClick={() =>
                      act(s.id, () =>
                        call(() =>
                          client.DELETE("/api/v1/me/sessions/{session_id}", {
                            params: { path: { session_id: s.id } },
                          }),
                        ),
                      )
                    }
                  >
                    {t("signOutDevice")}
                  </Button>
                )}
              </li>
            )) ?? <Bones n={2} />}
          </ul>
        </Card>
      </div>
      <Dialog open={adding} onClose={() => setAdding(false)} title={t("add")}>
        <Enrol
          allowTotp={!data?.totp}
          onDone={() => {
            setAdding(false);
            refresh();
          }}
        />
      </Dialog>
      <Dialog open={codes !== null} onClose={() => setCodes(null)} title={t("newCodes")}>
        {codes && <RecoveryCodes codes={codes} onDone={() => setCodes(null)} />}
      </Dialog>
    </>
  );
}
