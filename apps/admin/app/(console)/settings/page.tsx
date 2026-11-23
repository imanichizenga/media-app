"use client";
import { useQueryClient } from "@tanstack/react-query";
import { useTranslations } from "next-intl";
import { type FormEvent, useState } from "react";
import {
  Bone,
  Button,
  Card,
  ErrorState,
  Field,
  FormError,
  Notice,
  PageHeader,
  TextField,
} from "@/components/ui";
import { ApiError, call, client } from "@/lib/api";
import { keys, useSettings } from "@/lib/queries";

type Spec = {
  name: string;
  kind: "text" | "number" | "color" | "check" | "list" | "select";
  options?: string[];
};
const SECTIONS: Record<string, Spec[]> = {
  identity: [
    { name: "brand_name", kind: "text" },
    { name: "tagline_sw", kind: "text" },
    { name: "tagline_en", kind: "text" },
    { name: "accent_light", kind: "color" },
    { name: "accent_dark", kind: "color" },
  ],
  localization: [
    { name: "default_locale", kind: "select", options: ["sw", "en"] },
    { name: "timezone", kind: "text" },
  ],
  security: [
    { name: "idle_timeout_minutes", kind: "number" },
    { name: "absolute_timeout_hours", kind: "number" },
    { name: "step_up_minutes", kind: "number" },
    { name: "lockout_threshold", kind: "number" },
    { name: "lockout_minutes", kind: "number" },
    { name: "four_eyes", kind: "select", options: ["auto", "on", "off"] },
    { name: "geo_anomaly_action", kind: "select", options: ["off", "alert", "block"] },
    { name: "ip_allowlist_enabled", kind: "check" },
    { name: "ip_allowlist", kind: "list" },
  ],
};

function Section({ name, specs }: { name: string; specs: Spec[] }) {
  const t = useTranslations("settings");
  const c = useTranslations("common");
  const queries = useQueryClient();
  const { data, error, refetch } = useSettings(name);
  const [pending, setPending] = useState(false);
  const [problem, setProblem] = useState<unknown>(null);
  const [notice, setNotice] = useState("");
  const values = data?.values as Record<string, unknown> | undefined;
  const fields = problem instanceof ApiError ? problem.fields : {};
  async function save(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!data) return;
    const form = new FormData(e.currentTarget);
    const next: Record<string, unknown> = {};
    for (const s of specs) {
      const raw = String(form.get(s.name) ?? "");
      next[s.name] =
        s.kind === "number"
          ? Number(raw)
          : s.kind === "check"
            ? form.has(s.name)
            : s.kind === "list"
              ? raw.split(/[\s,]+/).filter(Boolean)
              : raw;
    }
    setPending(true);
    setProblem(null);
    setNotice("");
    try {
      const r = await call(() =>
        client.PUT("/api/v1/settings/{key}", {
          params: { path: { key: name } },
          body: { version: data.version, values: next, reason: "" },
        }),
      );
      // Refetch first: the form remounts on the new version and must not discard later typing.
      await queries.invalidateQueries({ queryKey: keys.settings(name) });
      setNotice(t(r.approval_required ? "sentForApproval" : "saved"));
    } catch (err) {
      setProblem(err);
    } finally {
      setPending(false);
    }
  }
  return (
    <Card>
      <h2 className="mb-4 text-headline-s">{t(`section.${name}` as never)}</h2>
      {error && !data ? (
        <ErrorState error={error} retry={refetch} />
      ) : (
        <form key={data?.version ?? "loading"} onSubmit={save} className="flex max-w-xl flex-col gap-4">
          <FormError error={problem} />
          {problem instanceof ApiError && Object.values(fields).length > 0 && (
            <p className="text-caption text-danger">{Object.values(fields).join(" ")}</p>
          )}
          {notice && <Notice tone="success">{notice}</Notice>}
          {specs.map((s) => {
            if (!values)
              return (
                <div key={s.name} className="flex flex-col gap-1" data-skeleton="field">
                  <span className="text-label">
                    <Bone className="w-32" />
                  </span>
                  <span className={s.kind === "list" ? "bone h-27 w-full" : "tap bone w-full"} />
                </div>
              );
            const label = t(`field.${s.name}` as never);
            const value = values[s.name];
            const disabled = !data?.can_edit || pending;
            if (s.kind === "check")
              return (
                <label key={s.name} className="tap flex items-center gap-3 text-label">
                  <input
                    type="checkbox"
                    name={s.name}
                    defaultChecked={Boolean(value)}
                    disabled={disabled}
                    className="size-5"
                  />
                  {label}
                </label>
              );
            if (s.kind === "list")
              return (
                <Field key={s.name} label={label} help={t("cidrHelp")} error={fields[s.name]}>
                  {(p) => (
                    <textarea
                      name={s.name}
                      rows={4}
                      defaultValue={(value as string[]).join("\n")}
                      disabled={disabled}
                      {...p}
                    />
                  )}
                </Field>
              );
            if (s.kind === "select")
              return (
                <Field key={s.name} label={label}>
                  {(p) => (
                    <select name={s.name} defaultValue={String(value)} disabled={disabled} {...p}>
                      {s.options?.map((o) => (
                        <option key={o} value={o}>
                          {t(`option.${o}` as never)}
                        </option>
                      ))}
                    </select>
                  )}
                </Field>
              );
            return (
              <TextField
                key={s.name}
                label={label}
                name={s.name}
                type={s.kind}
                defaultValue={String(value)}
                error={fields[s.name]}
                disabled={disabled}
              />
            );
          })}
          {data?.can_edit && (
            <Button type="submit" pending={pending} className="self-start">
              {c("save")}
            </Button>
          )}
        </form>
      )}
    </Card>
  );
}
export default function SettingsPage() {
  const t = useTranslations("settings");
  return (
    <>
      <PageHeader title={t("title")} lead={t("lead")} />
      <div className="flex flex-col gap-4">
        {Object.entries(SECTIONS).map(([name, specs]) => (
          <Section key={name} name={name} specs={specs} />
        ))}
      </div>
    </>
  );
}
