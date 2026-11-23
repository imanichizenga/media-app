"use client";
import type { Schemas } from "@news/api-client/admin";
import { useQueryClient } from "@tanstack/react-query";
import { CircleCheck, CircleDashed, CircleX, MinusCircle } from "lucide-react";
import { useParams } from "next/navigation";
import { useLocale, useTranslations } from "next-intl";
import { type FormEvent, useState } from "react";
import { IntegrationStatus } from "@/components/integration-status";
import {
  Badge,
  Bone,
  Button,
  Card,
  cx,
  Dialog,
  ErrorState,
  FormError,
  Notice,
  PageHeader,
  TextField,
} from "@/components/ui";
import { ApiError, call, client } from "@/lib/api";
import { keys, useCan, useIntegration, useTime } from "@/lib/queries";

const ICON = {
  passed: CircleCheck,
  failed: CircleX,
  skipped: MinusCircle,
  running: CircleDashed,
  pending: CircleDashed,
};
const COLOR = {
  passed: "text-success",
  failed: "text-danger",
  skipped: "text-text-tertiary",
  running: "text-accent motion-safe:animate-pulse",
  pending: "text-text-tertiary",
};

function Steps({ run }: { run: Schemas["TestRun"] }) {
  const t = useTranslations("integrations");
  const en = useLocale() === "en";
  return (
    <ol aria-label={t("steps")} aria-live="polite" className="flex flex-col gap-3">
      {run.steps.map((s) => {
        const Icon = ICON[s.status];
        return (
          <li key={s.key} className="flex gap-3">
            <Icon aria-hidden size={20} className={cx("mt-0.5 shrink-0", COLOR[s.status])} />
            <div className="min-w-0">
              <p>
                {en ? s.label_en : s.label_sw} <span className="sr-only">{t(`step.${s.status}`)}</span>
                {s.latency_ms > 0 && (
                  <span className="text-caption text-text-secondary"> · {s.latency_ms} ms</span>
                )}
              </p>
              {s.detail && <p className="text-caption break-words text-text-secondary">{s.detail}</p>}
              {s.remediation && <p className="text-caption break-words text-danger">{s.remediation}</p>}
            </div>
          </li>
        );
      })}
    </ol>
  );
}

function LoadingForm() {
  return (
    <div className="grid gap-4 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]" data-skeleton="form">
      <Card className="flex flex-col gap-4">
        {["a", "b", "c", "d", "e", "f"].map((k) => (
          <div key={k} className="flex flex-col gap-1">
            <span className="text-label">
              <Bone className="w-32" />
            </span>
            <span className="tap bone w-full" />
          </div>
        ))}
      </Card>
      <Card>
        <Bone className="w-40" />
      </Card>
    </div>
  );
}

export default function IntegrationDetail() {
  const { key } = useParams<{ key: string }>();
  const t = useTranslations("integrations");
  const c = useTranslations("common");
  const en = useLocale() === "en";
  const time = useTime();
  const can = useCan();
  const queries = useQueryClient();
  const { data, error, refetch } = useIntegration(key);
  const [pending, setPending] = useState<"" | "save" | "test" | "activate">("");
  const [problem, setProblem] = useState<unknown>(null);
  const [notice, setNotice] = useState("");
  const [override, setOverride] = useState(false);
  const [clear, setClear] = useState<Set<string>>(new Set());
  if (error && !data) return <ErrorState error={error} retry={refetch} />;
  if (!data)
    return (
      <>
        <PageHeader title={<Bone className="w-56" />} lead={<Bone className="w-80" />} />
        <LoadingForm />
      </>
    );

  const manage = can("integrations.manage");
  const editable = manage && pending !== "save";
  const fields = problem instanceof ApiError ? problem.fields : {};
  const refresh = () => queries.invalidateQueries({ queryKey: keys.integrations });
  async function act(kind: typeof pending, action: () => Promise<string | undefined>) {
    setPending(kind);
    setProblem(null);
    setNotice("");
    try {
      const message = (await action()) ?? "";
      // Refetch first: the form remounts on the new version and must not discard later typing.
      await refresh();
      setNotice(message);
    } catch (e) {
      setProblem(e);
      await refresh();
    } finally {
      setPending("");
    }
  }
  function save(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    const values: Record<string, unknown> = {};
    const secrets: Record<string, string | null> = {};
    for (const f of data?.schema ?? []) {
      const raw = String(form.get(f.name) ?? "");
      if (f.kind === "secret") {
        if (clear.has(f.name)) secrets[f.name] = null;
        else if (raw) secrets[f.name] = raw;
      } else
        values[f.name] = f.kind === "integer" ? Number(raw) : f.kind === "boolean" ? form.has(f.name) : raw;
    }
    act("save", async () => {
      await call(() =>
        client.PUT("/api/v1/integrations/{key}", {
          params: { path: { key } },
          body: { base_number: data?.latest?.number ?? 0, fields_: values, secrets },
        }),
      );
      setClear(new Set());
      return t("saved");
    });
  }
  const number = data.latest?.number ?? 0;
  const test = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    const params = Object.fromEntries(data.test_params.map((p) => [p, String(form.get(p) ?? "")]));
    act("test", async () => {
      await call(() =>
        client.POST("/api/v1/integrations/{key}/versions/{number}/test", {
          params: { path: { key, number } },
          body: { params },
        }),
      );
      return undefined;
    });
  };
  const activate = (reason: string) =>
    act("activate", async () => {
      const r = await call(() =>
        client.POST("/api/v1/integrations/{key}/versions/{number}/activate", {
          params: { path: { key, number } },
          body: { override_reason: reason },
        }),
      );
      setOverride(false);
      return t(r.approval_required ? "sentForApproval" : "activated");
    });
  const run = data.latest_test;
  const busy = run?.status === "queued" || run?.status === "running";
  const isActive = data.active_number === number && number > 0;

  return (
    <>
      <PageHeader
        title={data.name}
        lead={en ? data.description_en : data.description_sw}
        actions={<IntegrationStatus status={data.status} />}
      />
      <div className="mb-4 flex flex-col gap-3 empty:hidden">
        <FormError error={problem} />
        {notice && <Notice tone="success">{notice}</Notice>}
      </div>
      <div className="grid items-start gap-4 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]">
        <Card>
          <form key={number} onSubmit={save} className="flex flex-col gap-4" autoComplete="off">
            {data.schema.map((f) => {
              const label = en ? f.label_en : f.label_sw;
              const hint = data.latest?.secret_hints as Record<string, string> | undefined;
              const stored = hint?.[f.name];
              const value =
                (data.latest?.fields_ as Record<string, unknown> | undefined)?.[f.name] ?? f.default ?? "";
              if (f.kind === "boolean")
                return (
                  <label key={f.name} className="tap flex items-center gap-3 text-label">
                    <input
                      type="checkbox"
                      name={f.name}
                      defaultChecked={Boolean(value)}
                      disabled={!editable}
                      className="size-5"
                    />
                    {label}
                  </label>
                );
              if (f.kind === "secret")
                return (
                  <div key={f.name}>
                    <TextField
                      label={label}
                      name={f.name}
                      type="password"
                      autoComplete="new-password"
                      placeholder={clear.has(f.name) ? t("willClear") : stored}
                      help={stored ? t("secretKept") : undefined}
                      error={fields[f.name]}
                      disabled={!editable || clear.has(f.name)}
                    />
                    {stored && manage && (
                      <Button
                        variant="ghost"
                        className="px-0"
                        onClick={() =>
                          setClear((s) => {
                            const n = new Set(s);
                            n.has(f.name) ? n.delete(f.name) : n.add(f.name);
                            return n;
                          })
                        }
                      >
                        {t(clear.has(f.name) ? "keepSecret" : "clearSecret")}
                      </Button>
                    )}
                  </div>
                );
              return (
                <TextField
                  key={f.name}
                  label={label}
                  name={f.name}
                  type={f.kind === "integer" ? "number" : "text"}
                  defaultValue={String(value)}
                  help={(en ? f.help_en : f.help_sw) || undefined}
                  error={fields[f.name]}
                  required={f.is_required}
                  disabled={!editable}
                  spellCheck={false}
                />
              );
            })}
            {manage && (
              <Button type="submit" pending={pending === "save"} disabled={busy} className="self-start">
                {t("saveDraft")}
              </Button>
            )}
          </form>
        </Card>
        <div className="flex flex-col gap-4">
          <Card className="flex flex-col gap-4">
            <h2 className="text-headline-s">{t("testTitle")}</h2>
            {number === 0 ? (
              <p className="text-text-secondary">{t("saveFirst")}</p>
            ) : (
              <>
                {run ? (
                  <Steps run={run} />
                ) : (
                  <p className="text-text-secondary">{t("notTested", { number })}</p>
                )}
                {manage && (
                  <form onSubmit={test} className="flex flex-col gap-3">
                    {data.test_params.map((p) => (
                      <TextField
                        key={p}
                        label={t(`param.${p}` as never)}
                        name={p}
                        type={p === "to" ? "email" : "text"}
                        required
                        error={fields[p]}
                      />
                    ))}
                    <Button type="submit" variant="secondary" pending={pending === "test" || busy}>
                      {t("test")}
                    </Button>
                  </form>
                )}
                {manage && !isActive && (
                  <div className="flex flex-col gap-2 border-t border-border pt-4">
                    <Button
                      onClick={() => activate("")}
                      disabled={run?.status !== "passed"}
                      pending={pending === "activate"}
                    >
                      {t("activate", { number })}
                    </Button>
                    {run?.status !== "passed" && (
                      <p className="text-caption text-text-secondary">{t("activateHint")}</p>
                    )}
                    {run?.status === "failed" && can("integrations.override_test") && (
                      <Button variant="ghost" onClick={() => setOverride(true)}>
                        {t("override")}
                      </Button>
                    )}
                  </div>
                )}
                {isActive && <Notice tone="success">{t("isActive", { number })}</Notice>}
              </>
            )}
          </Card>
          <Card>
            <h2 className="text-headline-s">{t("history")}</h2>
            {data.history.length === 0 ? (
              <p className="mt-3 text-text-secondary">{t("noHistory")}</p>
            ) : (
              <ul className="mt-3 divide-y divide-border">
                {data.history.map((h) => (
                  <li
                    key={h.id}
                    className="flex flex-wrap items-center justify-between gap-2 py-2 text-caption"
                  >
                    <span>
                      v{h.version_number} · {h.started_by?.display_name ?? "—"} · {time(h.created_at)}
                    </span>
                    <Badge
                      tone={h.status === "passed" ? "success" : h.status === "failed" ? "danger" : "accent"}
                    >
                      {t(`run.${h.status}`)}
                    </Badge>
                  </li>
                ))}
              </ul>
            )}
          </Card>
        </div>
      </div>
      <Dialog
        open={override}
        onClose={() => setOverride(false)}
        title={t("overrideTitle")}
        description={t("overrideLead")}
      >
        <form
          onSubmit={(e) => {
            e.preventDefault();
            activate(String(new FormData(e.currentTarget).get("reason")));
          }}
          className="flex flex-col gap-4"
        >
          <FormError error={problem} />
          <TextField label={c("reason")} name="reason" minLength={10} required />
          <Button type="submit" variant="danger" pending={pending === "activate"}>
            {t("overrideConfirm")}
          </Button>
        </form>
      </Dialog>
    </>
  );
}
