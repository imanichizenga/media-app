import { cx } from "@news/ui/base";
import {
  ArrowLeft,
  Check,
  CircleCheck,
  CreditCard,
  Crown,
  LockKeyhole,
  RefreshCw,
  Smartphone,
  X,
} from "@news/ui/icons";
import type { Offer, Plan } from "@/lib/api";
import type { T } from "@/lib/i18n";
import { at, type Locale } from "@/lib/locale";
import { BUTTON } from "./button";

export const money = (n: number, locale: Locale) =>
  new Intl.NumberFormat(locale === "en" ? "en-TZ" : "sw-TZ", {
    style: "currency",
    currency: "TZS",
    currencyDisplay: "symbol",
    maximumFractionDigits: 0,
  }).format(n);

/**
 * The end of what everyone may read of a story for subscribers (ADR-0052): the last lines fade, and an invitation
 * takes their place. The site's top and its bar stay where they are, so a reader who does not pay simply goes on to
 * another story. A subscriber's island swaps the whole story in (islands/premium.ts) and this goes.
 */
export function Paywall({
  post,
  path,
  locale,
  t,
  offer,
}: {
  post: string;
  path: string;
  locale: Locale;
  t: T;
  offer: Offer | null;
}) {
  const monthly = offer?.plans.filter((p) => p.interval === "month").map((p) => p.price) ?? [];
  const from = monthly.length ? Math.min(...monthly) : null;
  const plans = at(locale, `/subscribe?next=${encodeURIComponent(path)}`);
  return (
    <section
      data-paywall={post}
      data-locale={locale}
      aria-labelledby="paywall-title"
      className="paywall relative flex flex-col items-center gap-4 text-center"
    >
      <div className="paywall-card relative w-full overflow-hidden rounded-xl border border-border bg-surface px-6 pt-10 pb-7 shadow-xl sm:px-10">
        <span aria-hidden className="paywall-glow" />
        <span
          aria-hidden
          className="paywall-crown relative mx-auto mb-4 grid size-14 place-items-center rounded-full text-white shadow-lg"
        >
          <Crown size={26} strokeWidth={2} />
        </span>
        <h2 id="paywall-title" className="relative font-serif text-headline-m lg:text-headline-l">
          {t("paywallTitle")}
        </h2>
        <p className="relative mx-auto mt-2 max-w-md text-body-l text-text-secondary">{t("paywallText")}</p>
        {from !== null && (
          <p className="relative mt-4 text-label font-semibold text-brand-text">
            {t("paywallFrom", { v: money(from, locale) })}
          </p>
        )}
        <div data-unlock hidden className="relative mt-6 items-center justify-center gap-2 text-label">
          <RefreshCw size={16} className="motion-safe:animate-spin" />
          {t("paywallUnlocking")}
        </div>
        <div data-offer className="relative mt-6 flex flex-col items-center gap-3">
          <a
            href={plans}
            data-subscribe
            className={cx(
              BUTTON,
              "h-13 w-full max-w-sm gap-2 rounded-full text-body-l font-semibold shadow-md",
            )}
          >
            <Crown size={18} />
            {t("paywallAction")}
          </a>
          <button
            type="button"
            data-paywall-sign-in
            data-intent={t("signInToSubscribe")}
            className="tap px-3 text-label font-medium text-text-primary underline-offset-4 hover:underline"
          >
            {t("paywallSignIn")}
          </button>
        </div>
      </div>
      <a
        href={at(locale, "/")}
        className="tap inline-flex items-center gap-2 px-3 text-label text-text-secondary hover:text-text-primary"
      >
        <ArrowLeft size={16} />
        {t("paywallFree")}
      </a>
    </section>
  );
}

const TONES = ["brand", "ember", "ocean", "forest", "violet", "night"];

/** One plan, Netflix's way: its colour and name on top, then what it costs and gives, line by line. */
function PlanCard({ plan, t, locale, first }: { plan: Plan; t: T; locale: Locale; first: boolean }) {
  const tone = TONES.includes(plan.tone) ? plan.tone : "brand";
  const per = plan.interval === "year" ? t("perYear") : t("perMonth");
  return (
    <label
      data-plan-card={plan.interval}
      className="plan-card group relative flex cursor-pointer flex-col rounded-xl border-2 border-border bg-surface p-2 transition has-checked:border-transparent"
    >
      <input
        type="radio"
        name="plan"
        value={plan.id}
        defaultChecked={first && plan.interval === "month"}
        data-pick={first ? "" : undefined}
        data-name={plan.name}
        data-price={money(plan.price, locale)}
        data-per={per}
        className="peer sr-only"
      />
      {plan.badge && (
        <span className="absolute -top-3 left-1/2 z-10 -translate-x-1/2 rounded-full bg-text-primary px-3 py-1 text-[11px] font-bold uppercase tracking-wide whitespace-nowrap text-bg shadow">
          {plan.badge}
        </span>
      )}
      <span
        className={cx(
          "plan-top relative flex min-h-28 flex-col justify-end rounded-lg p-4 text-white",
          `tone-${tone}`,
        )}
      >
        <span className="text-headline-s font-bold leading-tight">{plan.name}</span>
        {plan.tagline && <span className="mt-0.5 text-caption text-white/85">{plan.tagline}</span>}
        <span
          aria-hidden
          className="plan-tick absolute top-3 right-3 grid size-7 place-items-center rounded-full bg-white text-text-primary opacity-0 shadow transition group-has-checked:opacity-100"
        >
          <Check size={16} strokeWidth={3} />
        </span>
      </span>
      <span className="flex flex-col px-2 pt-3 pb-2">
        <span className="flex items-baseline justify-between gap-2 border-border border-b py-3">
          <span className="text-caption text-text-secondary">
            {plan.interval === "year" ? t("plansYearly") : t("plansMonthly")}
          </span>
          <span className="text-right">
            <span className="text-headline-s font-bold tabular-nums">{money(plan.price, locale)}</span>
            <span className="text-caption text-text-secondary">{per}</span>
          </span>
        </span>
        {plan.interval === "year" && (
          <span className="border-border border-b py-2.5 text-caption font-medium text-success">
            {t("plansEquivalent", { v: money(plan.monthly_equivalent, locale) })}
          </span>
        )}
        <span className="flex flex-col">
          {plan.features.map((f) => (
            <span
              key={f}
              className="flex items-start gap-2.5 border-border border-b py-2.5 text-label last:border-b-0"
            >
              <Check size={16} strokeWidth={2.5} className="mt-0.5 shrink-0 text-brand-text" />
              {f}
            </span>
          ))}
        </span>
      </span>
    </label>
  );
}

/** The plans page (ADR-0052): monthly or yearly, then a plan, then how to pay, in a sheet over the page. */
export function Plans({ offer, t, locale, next }: { offer: Offer; t: T; locale: Locale; next: string }) {
  const monthly = offer.plans.filter((p) => p.interval === "month");
  const yearly = offer.plans.filter((p) => p.interval === "year");
  const pick = (list: Plan[]) =>
    Math.max(
      0,
      list.findIndex((p) => p.highlighted),
    );
  const save = yearly.find((p) => p.badge)?.badge;
  const usable = offer.enabled && offer.plans.length > 0 && offer.methods.length > 0;
  return (
    <div
      data-plans
      data-locale={locale}
      data-next={next}
      className="plans mx-auto flex max-w-6xl flex-col gap-8 px-4 py-8 lg:py-12"
    >
      <header className="flex flex-col items-center gap-3 text-center">
        <span className="paywall-crown grid size-12 place-items-center rounded-full text-white shadow-lg">
          <Crown size={22} strokeWidth={2} />
        </span>
        <h1 className="font-serif text-headline-l lg:text-display">{t("plansTitle")}</h1>
        <p className="max-w-xl text-body-l text-text-secondary">{t("plansLead")}</p>
      </header>
      {!usable ? (
        <p className="mx-auto rounded-md bg-surface-sunken px-5 py-4 text-label">
          {offer.plans.length ? t("payUnavailable") : t("plansNone")}
        </p>
      ) : (
        <form data-plan-form className="flex flex-col gap-8" noValidate>
          {monthly.length > 0 && yearly.length > 0 && (
            <fieldset className="interval mx-auto flex rounded-full bg-surface-sunken p-1 text-label font-semibold">
              <legend className="sr-only">{t("plansTitle")}</legend>
              <label className="tap relative inline-flex cursor-pointer items-center rounded-full px-5 has-checked:bg-surface has-checked:shadow">
                <input type="radio" name="interval" value="month" defaultChecked className="sr-only" />
                {t("plansMonthly")}
              </label>
              <label className="tap relative inline-flex cursor-pointer items-center gap-2 rounded-full px-5 has-checked:bg-surface has-checked:shadow">
                <input type="radio" name="interval" value="year" className="sr-only" />
                {t("plansYearly")}
                {save && (
                  <span className="rounded-full bg-success-soft px-2 py-0.5 text-[11px] font-bold text-success">
                    {save}
                  </span>
                )}
              </label>
            </fieldset>
          )}
          {(
            [
              ["month", monthly],
              ["year", yearly],
            ] as const
          ).map(
            ([interval, list]) =>
              list.length > 0 && (
                <div
                  key={interval}
                  data-interval={interval}
                  role="radiogroup"
                  aria-label={interval === "year" ? t("plansYearly") : t("plansMonthly")}
                  className="plan-grid grid gap-5 pt-3 sm:grid-cols-2 lg:grid-cols-3"
                >
                  {list.map((plan, i) => (
                    <PlanCard key={plan.id} plan={plan} t={t} locale={locale} first={i === pick(list)} />
                  ))}
                </div>
              ),
          )}
          <p className="mx-auto max-w-2xl text-center text-caption text-text-secondary">{t("plansFine")}</p>
          <div className="plans-go sticky bottom-0 z-20 -mx-4 border-border border-t bg-bg/95 px-4 py-3 backdrop-blur max-lg:pb-[calc(env(safe-area-inset-bottom)+5rem)] lg:static lg:mx-auto lg:w-full lg:max-w-sm lg:border-0 lg:bg-transparent lg:p-0">
            <button type="submit" className={cx(BUTTON, "h-14 w-full rounded-md text-body-l font-semibold")}>
              {t("plansContinue")}
            </button>
          </div>
        </form>
      )}
      <PaySheet t={t} methods={offer.methods} />
    </div>
  );
}

/** How to pay, then the phone's approval, then welcome. Every step is drawn here; the island shows one. */
function PaySheet({ t, methods }: { t: T; methods: string[] }) {
  const mobile = methods.includes("mobile");
  const card = methods.includes("card");
  return (
    <dialog
      data-pay-sheet
      aria-labelledby="pay-title"
      data-say-phone={t("payPhoneInvalid")}
      data-say-failed={t("payFailed")}
      data-say-expired={t("payExpired")}
      data-say-unavailable={t("payUnavailable")}
      data-say-wait={t("payWaitText", { name: "#" })}
      data-say-until={t("paySuccessText", { when: "#" })}
      data-say-pay={t("payButton", { v: "#" })}
      data-say-title={t("payTitle", { name: "#" })}
      data-intent={t("signInToSubscribe")}
      className="sheet m-0 mt-auto w-full max-w-none rounded-t-2xl bg-surface p-0 text-text-primary shadow-2xl backdrop:bg-black/60 sm:m-auto sm:max-w-md sm:rounded-xl"
    >
      <div className="relative flex flex-col gap-5 px-5 pt-3 pb-[max(1.25rem,env(safe-area-inset-bottom))] sm:p-7">
        <span aria-hidden className="mx-auto h-1 w-10 rounded-full bg-border-strong sm:hidden" />
        <button
          type="button"
          data-sheet-close
          aria-label={t("close")}
          className="tap absolute top-2 right-2 grid w-11 place-items-center rounded-full text-text-secondary hover:bg-surface-sunken"
        >
          <X size={20} />
        </button>

        <form data-step="method" data-pay-form className="flex flex-col gap-5" noValidate>
          <div className="flex flex-col gap-1 pr-10">
            <h2 id="pay-title" data-pay-title className="font-serif text-headline-m">
              {t("plansContinue")}
            </h2>
            <p data-pay-summary className="text-text-secondary tabular-nums" />
          </div>
          <fieldset className="flex flex-col gap-3">
            <legend className="sr-only">{t("payTitle", { name: "" })}</legend>
            {mobile && (
              <label className="pay-method flex cursor-pointer items-center gap-4 rounded-xl border-2 border-border p-4 has-checked:border-text-primary">
                <input type="radio" name="method" value="mobile" defaultChecked className="peer sr-only" />
                <span className="grid size-11 shrink-0 place-items-center rounded-full bg-brand-soft text-brand-text">
                  <Smartphone size={22} />
                </span>
                <span className="flex min-w-0 flex-1 flex-col">
                  <span className="font-semibold">{t("payMobile")}</span>
                  <span className="text-caption text-text-secondary">{t("payMobileHint")}</span>
                </span>
                <span
                  aria-hidden
                  className="pay-dot size-5 shrink-0 rounded-full border-2 border-border-strong"
                />
              </label>
            )}
            {card && (
              <label className="pay-method flex cursor-pointer items-center gap-4 rounded-xl border-2 border-border p-4 has-checked:border-text-primary">
                <input
                  type="radio"
                  name="method"
                  value="card"
                  defaultChecked={!mobile}
                  className="peer sr-only"
                />
                <span className="grid size-11 shrink-0 place-items-center rounded-full bg-surface-sunken">
                  <CreditCard size={22} />
                </span>
                <span className="flex min-w-0 flex-1 flex-col">
                  <span className="font-semibold">{t("payCard")}</span>
                  <span className="text-caption text-text-secondary">{t("payCardHint")}</span>
                </span>
                <span
                  aria-hidden
                  className="pay-dot size-5 shrink-0 rounded-full border-2 border-border-strong"
                />
              </label>
            )}
          </fieldset>
          {mobile && (
            <div data-phone className="flex flex-col gap-2">
              <label htmlFor="pay-phone" className="text-label font-medium">
                {t("payPhone")}
              </label>
              <div className="flex gap-2">
                <span className="grid h-12 shrink-0 place-items-center rounded-md border border-border bg-surface-sunken px-3 text-label tabular-nums">
                  🇹🇿 +255
                </span>
                <input
                  id="pay-phone"
                  name="phone"
                  type="tel"
                  inputMode="tel"
                  autoComplete="tel-national"
                  placeholder="712 345 678"
                  maxLength={20}
                  className="h-12 w-full rounded-md border border-border-strong bg-surface px-4 text-body-l outline-none placeholder:text-text-tertiary focus:border-text-primary"
                />
              </div>
            </div>
          )}
          <p
            data-pay-error
            role="alert"
            hidden
            className="rounded-md bg-danger-soft px-4 py-3 text-label text-danger"
          />
          <button
            type="submit"
            data-pay-go
            className={cx(BUTTON, "h-13 w-full gap-2 rounded-md text-body-l font-semibold")}
          >
            <LockKeyhole size={18} />
            <span data-pay-label />
          </button>
          <p className="flex items-center justify-center gap-1.5 text-caption text-text-secondary">
            <LockKeyhole size={13} />
            {t("paySecure")}
          </p>
        </form>

        <div data-step="wait" hidden className="flex flex-col items-center gap-4 py-6 text-center">
          <span
            aria-hidden
            className="pay-ring relative grid size-24 place-items-center rounded-full bg-brand-soft text-brand-text"
          >
            <Smartphone size={40} />
          </span>
          <h2 className="font-serif text-headline-m">{t("payWaitTitle")}</h2>
          <p data-pay-wait className="max-w-xs text-text-secondary" />
          <p className="inline-flex items-center gap-2 text-caption text-text-secondary">
            <RefreshCw size={14} className="motion-safe:animate-spin" />
            {t("payChecking")}
          </p>
        </div>

        <div data-step="card" hidden className="flex flex-col items-center gap-4 py-8 text-center">
          <span aria-hidden className="grid size-20 place-items-center rounded-full bg-surface-sunken">
            <CreditCard size={34} />
          </span>
          <p className="text-body-l">{t("payCardRedirect")}</p>
        </div>

        <div data-step="done" hidden className="flex flex-col items-center gap-4 py-6 text-center">
          <span
            aria-hidden
            className="pay-done grid size-24 place-items-center rounded-full text-white shadow-lg"
          >
            <CircleCheck size={48} strokeWidth={1.75} />
          </span>
          <h2 className="font-serif text-headline-m">{t("paySuccessTitle")}</h2>
          <p data-pay-until className="text-text-secondary" />
          <a
            data-pay-continue
            href="/"
            className={cx(BUTTON, "h-13 w-full rounded-md text-body-l font-semibold")}
          >
            {t("payContinue")}
          </a>
        </div>

        <div data-step="failed" hidden className="flex flex-col items-center gap-4 py-6 text-center">
          <span
            aria-hidden
            className="grid size-20 place-items-center rounded-full bg-danger-soft text-danger"
          >
            <X size={36} />
          </span>
          <p data-pay-failed className="text-body-l" />
          <button type="button" data-pay-again className={cx(BUTTON, "h-12 w-full rounded-md font-semibold")}>
            {t("payTryAgain")}
          </button>
        </div>
      </div>
    </dialog>
  );
}
