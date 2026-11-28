"use client";
import type { Schemas } from "@news/api-client/admin";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Check, Crown, Pencil, Plus } from "lucide-react";
import { useFormatter, useTranslations } from "next-intl";
import { type FormEvent, useState } from "react";
import {
  Badge,
  Bone,
  Button,
  Card,
  Dialog,
  Empty,
  ErrorState,
  Field,
  FormError,
  PageHeader,
  Table,
  Td,
  TextField,
  Row as Tr,
} from "@/components/ui";
import { ApiError, call, client } from "@/lib/api";
import { useCan } from "@/lib/queries";

type Plan = Schemas["PlanAdmin"];
type Payment = Schemas["PaymentAdmin"];
const TONES = ["brand", "ember", "ocean", "forest", "violet", "night"] as const;
/** The same colours as the website's plan cards (web/app/globals.css), for the preview here. */
const GRADIENT: Record<string, string> = {
  brand: "linear-gradient(135deg, var(--color-brand-strong), var(--color-brand) 55%, #e4572e)",
  ember: "linear-gradient(135deg, #6d1a0c, #d9481a 55%, #f59e3d)",
  ocean: "linear-gradient(135deg, #0a2463, #1d4fd8 55%, #3aa0ff)",
  forest: "linear-gradient(135deg, #0b3a2c, #12795a 55%, #3cbf88)",
  violet: "linear-gradient(135deg, #2a0d5c, #6a28d4 55%, #c06bff)",
  night: "linear-gradient(135deg, #070b14, #222c45 55%, #4d5875)",
};
const KEYS = {
  plans: ["subscriptions", "plans"],
  payments: ["subscriptions", "payments"],
  summary: ["subscriptions", "summary"],
};
const tzs = (n: number) => `TSh ${new Intl.NumberFormat("en").format(n)}`;

/** Paid reading (ADR-0052): what the newsroom sells, and what readers paid. */
export default function SubscriptionsPage() {
  const t = useTranslations("subscriptions");
  const can = useCan();
  const [editing, setEditing] = useState<Plan | "new" | null>(null);
  const plans = useQuery({
    queryKey: KEYS.plans,
    queryFn: () => call(() => client.GET("/api/v1/subscriptions/plans")),
  });
  const summary = useQuery({
    queryKey: KEYS.summary,
    queryFn: () => call(() => client.GET("/api/v1/subscriptions/summary")),
  });
  const manage = can("settings.manage");
  return (
    <>
      <PageHeader
        title={t("title")}
        lead={t("lead")}
        actions={
          manage && (
            <Button onClick={() => setEditing("new")}>
              <Plus aria-hidden size={16} />
              {t("newPlan")}
            </Button>
          )
        }
      />
      <dl className="mb-6 grid grid-cols-2 gap-3 lg:grid-cols-5">
        {(
          [
            ["subscribers", summary.data?.subscribers],
            ["monthly", summary.data?.monthly],
            ["yearly", summary.data?.yearly],
            ["revenue", summary.data === undefined ? undefined : tzs(summary.data.revenue_30d)],
            ["pending", summary.data?.pending],
          ] as const
        ).map(([key, value]) => (
          <Card key={key} className="flex flex-col gap-1 p-4">
            <dt className="text-caption text-text-secondary">{t(key)}</dt>
            <dd className="text-headline-s tabular-nums">{value ?? <Bone className="w-16" />}</dd>
          </Card>
        ))}
      </dl>
      <h2 className="mb-3 text-headline-s">{t("plans")}</h2>
      {plans.error && !plans.data ? (
        <ErrorState error={plans.error} retry={plans.refetch} />
      ) : plans.data && plans.data.length === 0 ? (
        <Card>
          <Empty title={t("noPlans")} />
        </Card>
      ) : (
        <ul className="mb-8 grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {(plans.data ?? [undefined, undefined, undefined]).map((p, i) => (
            <li key={p?.id ?? i}>
              <PlanTile plan={p} onEdit={manage && p ? () => setEditing(p) : undefined} />
            </li>
          ))}
        </ul>
      )}
      <Payments />
      {editing && <PlanDialog plan={editing === "new" ? null : editing} onClose={() => setEditing(null)} />}
    </>
  );
}

function PlanTile({ plan, onEdit }: { plan?: Plan; onEdit?: () => void }) {
  const t = useTranslations("subscriptions");
  if (!plan) return <Card className="h-56 animate-pulse" />;
  return (
    <Card className={`flex h-full flex-col gap-3 p-3 ${plan.is_active ? "" : "opacity-60"}`}>
      <div
        className="relative flex min-h-24 flex-col justify-end rounded-md p-4 text-white"
        style={{ background: GRADIENT[plan.tone ?? "brand"] }}
      >
        {plan.badge_en && (
          <span className="absolute top-3 left-3 rounded-full bg-black/70 px-2 py-0.5 text-[11px] font-bold uppercase">
            {plan.badge_en}
          </span>
        )}
        {plan.highlighted && <Crown aria-hidden size={18} className="absolute top-3 right-3" />}
        <span className="text-title font-bold">
          {plan.name_en} · {plan.name_sw}
        </span>
        <span className="text-caption text-white/85">{plan.tagline_en}</span>
      </div>
      <div className="flex items-baseline justify-between px-1">
        <span className="text-headline-s tabular-nums">
          {tzs(plan.price)}
          <span className="text-caption text-text-secondary">
            {plan.interval === "year" ? t("perYear") : t("perMonth")}
          </span>
        </span>
        {plan.is_active ? (
          <Badge tone="success">{t("activeCount", { n: plan.subscribers })}</Badge>
        ) : (
          <Badge>{t("hidden")}</Badge>
        )}
      </div>
      <ul className="flex flex-1 flex-col gap-1 px-1 text-label">
        {(plan.features_en ?? []).map((f) => (
          <li key={f} className="flex items-start gap-2">
            <Check aria-hidden size={14} className="mt-1 shrink-0 text-brand-text" />
            {f}
          </li>
        ))}
      </ul>
      <div className="flex items-center justify-between px-1">
        <code className="text-caption text-text-secondary">{plan.code}</code>
        {onEdit && (
          <Button variant="secondary" onClick={onEdit}>
            <Pencil aria-hidden size={14} />
            {t("editPlan")}
          </Button>
        )}
      </div>
    </Card>
  );
}

function PlanDialog({ plan, onClose }: { plan: Plan | null; onClose: () => void }) {
  const t = useTranslations("subscriptions");
  const queries = useQueryClient();
  const [problem, setProblem] = useState<unknown>(null);
  const [pending, setPending] = useState(false);
  const [tone, setTone] = useState<string>(plan?.tone ?? "brand");
  const fields = problem instanceof ApiError ? problem.fields : {};
  const lines = (v: FormDataEntryValue | null) =>
    String(v ?? "")
      .split("\n")
      .map((x) => x.trim())
      .filter(Boolean);
  async function save(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const body = {
      code: String(f.get("code") ?? "").trim(),
      interval: String(f.get("interval")) as "month" | "year",
      price: Number(f.get("price")),
      name_sw: String(f.get("name_sw") ?? ""),
      name_en: String(f.get("name_en") ?? ""),
      tagline_sw: String(f.get("tagline_sw") ?? ""),
      tagline_en: String(f.get("tagline_en") ?? ""),
      features_sw: lines(f.get("features_sw")),
      features_en: lines(f.get("features_en")),
      badge_sw: String(f.get("badge_sw") ?? ""),
      badge_en: String(f.get("badge_en") ?? ""),
      tone: tone as Plan["tone"],
      highlighted: f.get("highlighted") === "on",
      is_active: f.get("is_active") === "on",
      position: Number(f.get("position") ?? 0),
    };
    setPending(true);
    setProblem(null);
    try {
      if (plan)
        await call(() =>
          client.PUT("/api/v1/subscriptions/plans/{plan_id}", {
            params: { path: { plan_id: plan.id } },
            body,
          }),
        );
      else await call(() => client.POST("/api/v1/subscriptions/plans", { body }));
      await queries.invalidateQueries({ queryKey: ["subscriptions"] });
      onClose();
    } catch (error) {
      setProblem(error);
    } finally {
      setPending(false);
    }
  }
  async function remove() {
    if (!plan) return;
    setPending(true);
    try {
      await call(() =>
        client.DELETE("/api/v1/subscriptions/plans/{plan_id}", { params: { path: { plan_id: plan.id } } }),
      );
      await queries.invalidateQueries({ queryKey: ["subscriptions"] });
      onClose();
    } catch (error) {
      setProblem(error);
    } finally {
      setPending(false);
    }
  }
  return (
    <Dialog open onClose={onClose} title={plan ? t("editPlan") : t("newPlan")} wide>
      <form onSubmit={save} className="grid gap-4 sm:grid-cols-2" noValidate>
        <TextField
          label={t("code")}
          help={t("codeHelp")}
          name="code"
          defaultValue={plan?.code ?? ""}
          pattern="[a-z0-9-]+"
          required
          error={fields.code}
        />
        <Field label={t("interval")} error={fields.interval}>
          {(c) => (
            <select {...c} name="interval" defaultValue={plan?.interval ?? "month"}>
              <option value="month">{t("month")}</option>
              <option value="year">{t("year")}</option>
            </select>
          )}
        </Field>
        <TextField
          label={t("price")}
          help={t("priceHelp")}
          name="price"
          type="number"
          min={500}
          step={100}
          defaultValue={plan?.price ?? 5000}
          error={fields.price}
        />
        <TextField
          label={t("position")}
          name="position"
          type="number"
          min={0}
          defaultValue={plan?.position ?? 0}
        />
        <TextField
          label={t("nameSw")}
          name="name_sw"
          defaultValue={plan?.name_sw ?? ""}
          error={fields.name_sw}
        />
        <TextField
          label={t("nameEn")}
          name="name_en"
          defaultValue={plan?.name_en ?? ""}
          error={fields.name_en}
        />
        <TextField label={t("taglineSw")} name="tagline_sw" defaultValue={plan?.tagline_sw ?? ""} />
        <TextField label={t("taglineEn")} name="tagline_en" defaultValue={plan?.tagline_en ?? ""} />
        <Field label={t("featuresSw")} error={fields.features_sw}>
          {(c) => (
            <textarea
              {...c}
              name="features_sw"
              rows={5}
              defaultValue={(plan?.features_sw ?? []).join("\n")}
              className={`${c.className} py-2`}
            />
          )}
        </Field>
        <Field label={t("featuresEn")} error={fields.features_en}>
          {(c) => (
            <textarea
              {...c}
              name="features_en"
              rows={5}
              defaultValue={(plan?.features_en ?? []).join("\n")}
              className={`${c.className} py-2`}
            />
          )}
        </Field>
        <TextField
          label={t("badgeSw")}
          help={t("badgeHelp")}
          name="badge_sw"
          defaultValue={plan?.badge_sw ?? ""}
        />
        <TextField
          label={t("badgeEn")}
          help={t("badgeHelp")}
          name="badge_en"
          defaultValue={plan?.badge_en ?? ""}
        />
        <fieldset className="flex flex-col gap-2 sm:col-span-2">
          <legend className="mb-1 text-label">{t("tone")}</legend>
          <div className="flex flex-wrap gap-3">
            {TONES.map((x) => (
              <label key={x} className="flex cursor-pointer flex-col items-center gap-1 text-caption">
                <input
                  type="radio"
                  name="tone"
                  value={x}
                  checked={tone === x}
                  onChange={() => setTone(x)}
                  className="peer sr-only"
                />
                <span
                  aria-hidden
                  className="size-12 rounded-md ring-offset-2 ring-offset-surface-raised peer-checked:ring-2 peer-checked:ring-text-primary peer-focus-visible:ring-2"
                  style={{ background: GRADIENT[x] }}
                />
                {t(`tone_${x}` as never)}
              </label>
            ))}
          </div>
        </fieldset>
        <label className="tap flex items-center gap-3 text-label">
          <input
            type="checkbox"
            name="highlighted"
            defaultChecked={plan?.highlighted ?? false}
            className="size-5"
          />
          {t("highlighted")}
        </label>
        <label className="tap flex items-center gap-3 text-label">
          <input
            type="checkbox"
            name="is_active"
            defaultChecked={plan?.is_active ?? true}
            className="size-5"
          />
          {t("active")}
        </label>
        <div className="sm:col-span-2">
          <FormError error={problem} />
        </div>
        <div className="flex flex-wrap items-center justify-between gap-3 sm:col-span-2">
          {plan ? (
            <Button variant="secondary" onClick={remove} disabled={pending} title={t("removeHelp")}>
              {t("remove")}
            </Button>
          ) : (
            <span />
          )}
          <Button type="submit" pending={pending}>
            {t("save")}
          </Button>
        </div>
      </form>
    </Dialog>
  );
}

function Payments() {
  const t = useTranslations("subscriptions");
  const format = useFormatter();
  const { data, error, refetch } = useQuery({
    queryKey: KEYS.payments,
    queryFn: () => call(() => client.GET("/api/v1/subscriptions/payments")),
  });
  const tone = (s: Payment["status"]) =>
    s === "completed" ? "success" : s === "pending" ? "warning" : s === "failed" ? "danger" : "neutral";
  return (
    <>
      <h2 className="mb-3 text-headline-s">{t("payments")}</h2>
      {error && !data ? (
        <ErrorState error={error} retry={refetch} />
      ) : data && data.results.length === 0 ? (
        <Card>
          <Empty title={t("noPayments")} />
        </Card>
      ) : (
        <Table
          label={t("payments")}
          head={[t("when"), t("reader"), t("plan"), t("method"), t("amount"), t("phone"), t("status")]}
        >
          {(data?.results ?? []).map((p) => (
            <Tr key={p.id}>
              <Td>{format.dateTime(new Date(p.created_at), { dateStyle: "medium", timeStyle: "short" })}</Td>
              <Td>{p.reader}</Td>
              <Td>{p.plan}</Td>
              <Td>{t(p.method)}</Td>
              <Td className="tabular-nums">{tzs(p.amount)}</Td>
              <Td className="tabular-nums">{p.phone}</Td>
              <Td>
                <Badge tone={tone(p.status)}>{t(`status_${p.status}` as never)}</Badge>
              </Td>
            </Tr>
          ))}
        </Table>
      )}
    </>
  );
}
