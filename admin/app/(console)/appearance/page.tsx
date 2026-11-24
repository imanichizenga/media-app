"use client";
import type { Schemas } from "@news/api-client/admin";
import {
  check,
  contrast,
  DEFAULT,
  derive,
  failures,
  nearest,
  THEMES,
  type ThemeKey,
  themeName,
  themeNote,
  variables,
} from "@news/design-tokens/theme";
import type { Logo } from "@news/ui/news";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Check, CircleCheck, Info, RotateCcw, TriangleAlert, Upload } from "lucide-react";
import { useFormatter, useLocale, useTranslations } from "next-intl";
import { useMemo, useRef, useState } from "react";
import { PreviewFrame } from "@/components/appearance/frame";
import {
  Bone,
  Button,
  Card,
  cx,
  ErrorState,
  Field,
  FormError,
  Notice,
  PageHeader,
  TextField,
} from "@/components/ui";
import { ApiError, call, client } from "@/lib/api";
import { PREVIEW_SCREENS, type PreviewScreen } from "@/lib/preview";

type Data = Schemas["BrandData"];
type Brand = Schemas["Brand"];
type Slot = "wordmark_light" | "wordmark_dark" | "symbol";
type Scheme = "light" | "dark";
const KEY = ["brand"] as const;
/** The shape of the form before the answer comes: what it shows is bones, where it shows them is final. */
const BLANK: Data = {
  identity: {
    brand_name: "",
    tagline_sw: "",
    tagline_en: "",
    wordmark_light: "",
    wordmark_dark: "",
    symbol: "",
  },
  appearance: { schema_version: 1, theme: "signature", color: DEFAULT.color, dark_color: "" },
};
/** A control that has not heard its value yet. */
const Waiting = ({ label, help }: { label: string; help?: string }) => (
  <div className="flex flex-col gap-1" data-skeleton="field">
    <span className="text-label">{label}</span>
    <span aria-hidden className="tap bone block! w-full" />
    {help && <p className="text-caption text-text-secondary">{help}</p>}
  </div>
);
const HEX = /^#[0-9a-f]{6}$/;
const PHONE = { width: 390, height: 844 };
const DESK = { width: 1280, height: 844 };

/** The stylesheet already on the page, asked for again. */
const recolour = () =>
  document
    .querySelector<HTMLLinkElement>("link[data-brand-theme]")
    ?.setAttribute("href", `/theme/current.css?${Date.now()}`);

export default function AppearancePage() {
  const t = useTranslations("appearance");
  const [notice, setNotice] = useState("");
  const { data, error, refetch } = useQuery({
    queryKey: KEY,
    queryFn: () => call(() => client.GET("/api/v1/brand")),
  });
  return (
    <>
      <PageHeader title={t("title")} lead={t("lead")} />
      {error && !data ? (
        <ErrorState error={error} retry={refetch} />
      ) : (
        <Editor key={data?.version ?? "loading"} brand={data} notice={notice} setNotice={setNotice} />
      )}
    </>
  );
}

function Editor({
  brand,
  notice,
  setNotice,
}: {
  brand?: Brand;
  /** Kept by the page: publishing starts this form again from the new version. */
  notice: string;
  setNotice: (text: string) => void;
}) {
  const t = useTranslations("appearance");
  const queries = useQueryClient();
  const locale = useLocale() as "sw" | "en";
  const [data, setData] = useState<Data | undefined>(brand?.data);
  const [logos, setLogos] = useState<Record<Slot, Logo | null>>({
    wordmark_light: brand?.identity.wordmark_light ?? null,
    wordmark_dark: brand?.identity.wordmark_dark?.derived ? null : (brand?.identity.wordmark_dark ?? null),
    symbol: brand?.identity.symbol ?? null,
  });
  const [white, setWhite] = useState<Logo | null>(
    brand?.identity.wordmark_dark?.derived ? brand.identity.wordmark_dark : null,
  );
  const [note, setNote] = useState("");
  const [pending, setPending] = useState(false);
  const [problem, setProblem] = useState<unknown>(null);
  const loading = data === undefined;
  const d = data ?? BLANK;
  const look = d.appearance;
  const color = HEX.test(look.color) ? look.color : "";
  const dark = HEX.test(look.dark_color) ? look.dark_color : "";
  const bad = useMemo(() => (color ? failures(color) : []), [color]);
  const badDark = useMemo(() => (color && dark ? failures(color, dark, "dark") : []), [color, dark]);
  const typed = Boolean(color && (look.dark_color === "" || dark));
  const valid = typed && bad.length === 0 && badDark.length === 0;
  const disabled = !brand?.can_edit || pending;
  const changed = JSON.stringify(data) !== JSON.stringify(brand?.data);
  const setLook = (next: Partial<Data["appearance"]>) =>
    setData((d) => d && { ...d, appearance: { ...d.appearance, ...next } });
  const setWho = (next: Partial<Data["identity"]>) =>
    setData((d) => d && { ...d, identity: { ...d.identity, ...next } });
  const shown = useMemo(
    () => ({
      name: data?.identity.brand_name || "—",
      light: logos.wordmark_light,
      dark: logos.wordmark_dark ?? white,
    }),
    [data?.identity.brand_name, logos, white],
  );
  const run = async (action: () => Promise<{ approval_required: boolean }>) => {
    setPending(true);
    setProblem(null);
    setNotice("");
    try {
      const r = await action();
      setNotice(t(r.approval_required ? "sentForApproval" : "published"));
      setNote("");
      recolour();
      await Promise.all([
        queries.invalidateQueries({ queryKey: KEY }),
        queries.invalidateQueries({ queryKey: ["session"] }),
      ]);
    } catch (err) {
      setProblem(err);
    } finally {
      setPending(false);
    }
  };
  return (
    <div className="grid items-start gap-6 xl:grid-cols-[minmax(0,1fr)_minmax(0,1.1fr)]">
      <div className="flex flex-col gap-6">
        <Themes
          look={loading ? undefined : look}
          color={bad.length ? "" : color}
          dark={dark}
          brand={shown}
          locale={locale}
          disabled={disabled}
          onPick={(theme) => setLook({ theme })}
        />
        <Card>
          <h2 className="mb-4 text-headline-s">{t("color")}</h2>
          <div className="flex flex-col gap-6">
            <ColorField
              loading={loading}
              label={t("brandColor")}
              help={t("brandColorHelp")}
              value={look.color}
              disabled={disabled}
              onChange={(v) => setLook({ color: v })}
            />
            {color && (
              <Verdict
                loading={loading}
                bad={bad}
                pick={() => nearest(color)}
                onFix={(v) => setLook({ color: v })}
                disabled={disabled}
              />
            )}
            {color && bad.length === 0 && (
              <Pairs
                loading={loading}
                theme={look.theme as ThemeKey}
                color={color}
                dark={badDark.length ? "" : dark}
              />
            )}
            <div className="border-border border-t pt-4">
              <label className="tap flex items-center gap-3 text-label">
                <input
                  type="checkbox"
                  className="size-5"
                  checked={look.dark_color !== ""}
                  disabled={disabled || !color || bad.length > 0}
                  onChange={(e) =>
                    setLook({
                      dark_color: e.target.checked
                        ? (derive("signature", "dark", color)["brand-text"] ?? "")
                        : "",
                    })
                  }
                />
                {t("ownDark")}
              </label>
              <p className="text-caption text-text-secondary">{t("ownDarkHelp")}</p>
            </div>
            {look.dark_color !== "" && (
              <>
                <ColorField
                  label={t("darkColor")}
                  value={look.dark_color}
                  disabled={disabled}
                  onChange={(v) => setLook({ dark_color: v })}
                />
                {dark && color && (
                  <Verdict
                    bad={badDark}
                    pick={() => nearest(color, dark, "dark")}
                    onFix={(v) => setLook({ dark_color: v })}
                    disabled={disabled}
                  />
                )}
              </>
            )}
          </div>
        </Card>
        <Card>
          <h2 className="mb-4 text-headline-s">{t("identity")}</h2>
          <div className="flex flex-col gap-4">
            {(["brand_name", "tagline_sw", "tagline_en"] as const).map((name) =>
              loading ? (
                <Waiting key={name} label={t(name)} />
              ) : (
                <TextField
                  key={name}
                  label={t(name)}
                  value={d.identity[name]}
                  maxLength={name === "brand_name" ? 60 : 140}
                  disabled={disabled}
                  onChange={(e) => setWho({ [name]: e.target.value })}
                />
              ),
            )}
          </div>
        </Card>
        <Card>
          <h2 className="text-headline-s">{t("logos")}</h2>
          <p className="mb-4 text-caption text-text-secondary">{t("logosHelp")}</p>
          <ul className="flex flex-col gap-6">
            {(["wordmark_light", "wordmark_dark", "symbol"] as const).map((slot) => (
              <LogoSlot
                loading={loading}
                key={slot}
                slot={slot}
                logo={logos[slot]}
                fallback={slot === "wordmark_dark" ? white : null}
                name={d.identity.brand_name}
                disabled={disabled}
                onChange={(logo, inWhite) => {
                  setLogos((l) => ({ ...l, [slot]: logo }));
                  if (slot === "wordmark_light") setWhite(inWhite);
                  setWho({ [slot]: logo?.id ?? "" });
                }}
              />
            ))}
          </ul>
        </Card>
        <p className="flex gap-3 rounded-sm bg-surface-sunken p-3 text-caption text-text-secondary">
          <Info aria-hidden size={18} className="mt-0.5 shrink-0" />
          {t("buildTime")}
        </p>
        <Card className="flex flex-col gap-4">
          <FormError error={problem} />
          {problem instanceof ApiError && Object.values(problem.fields).length > 0 && (
            <p className="text-caption text-danger">{Object.values(problem.fields).join(" ")}</p>
          )}
          {notice && <Notice tone="success">{notice}</Notice>}
          {brand?.approval_pending && <Notice tone="warning">{t("waiting")}</Notice>}
          <TextField
            label={t("note")}
            help={t("noteHelp")}
            value={note}
            maxLength={500}
            disabled={disabled}
            onChange={(e) => setNote(e.target.value)}
          />
          <div className="flex flex-wrap gap-2">
            <Button
              pending={pending}
              disabled={!brand?.can_edit || !valid || !changed || !data?.identity.brand_name.trim()}
              onClick={() =>
                brand &&
                data &&
                run(() =>
                  call(() => client.PUT("/api/v1/brand", { body: { version: brand.version, data, note } })),
                )
              }
            >
              {t("publish")}
            </Button>
            {changed && brand && (
              <Button variant="ghost" disabled={pending} onClick={() => setData(brand.data)}>
                {t("discard")}
              </Button>
            )}
          </div>
        </Card>
        <History
          version={brand?.version}
          disabled={disabled}
          onRestore={(number) =>
            run(() =>
              call(() =>
                client.POST("/api/v1/brand/versions/{number}/restore", {
                  params: { path: { number } },
                  body: { version: brand?.version ?? 0 },
                }),
              ),
            )
          }
        />
      </div>
      <LivePreview
        theme={look.theme as ThemeKey}
        color={bad.length ? "" : color}
        dark={badDark.length ? "" : dark}
        brand={shown}
        locale={locale}
      />
    </div>
  );
}

type Shown = { name: string; light: Logo | null; dark: Logo | null };
/** An unfinished or failing colour leaves the preview on the last one that worked. */
function useVariables(theme: ThemeKey, scheme: Scheme, color: string, dark: string) {
  const last = useRef("#b5121b");
  if (color) last.current = color;
  const base = color || last.current;
  return useMemo(() => variables(derive(theme, scheme, base, dark)), [theme, scheme, base, dark]);
}

function Themes({
  look,
  color,
  dark,
  brand,
  locale,
  disabled,
  onPick,
}: {
  look?: Data["appearance"];
  color: string;
  dark: string;
  brand: Shown;
  locale: "sw" | "en";
  disabled: boolean;
  onPick: (theme: ThemeKey) => void;
}) {
  const t = useTranslations("appearance");
  return (
    <Card>
      <h2 className="mb-4 text-headline-s">{t("theme")}</h2>
      <fieldset disabled={disabled} className="grid gap-4 sm:grid-cols-3">
        <legend className="sr-only">{t("theme")}</legend>
        {THEMES.map((theme) => (
          <ThemeCard
            key={theme}
            theme={theme}
            on={look?.theme === theme}
            {...{ color, dark, brand, locale }}
            onPick={() => onPick(theme)}
          />
        ))}
      </fieldset>
    </Card>
  );
}
function ThemeCard({
  theme,
  on,
  color,
  dark,
  brand,
  locale,
  onPick,
}: {
  theme: ThemeKey;
  on: boolean;
  color: string;
  dark: string;
  brand: Shown;
  locale: "sw" | "en";
  onPick: () => void;
}) {
  const vars = useVariables(theme, "light", color, dark);
  const state = useMemo(
    () => ({ screen: "home" as const, scheme: "light" as const, locale, variables: vars, brand }),
    [locale, vars, brand],
  );
  return (
    <label
      className={cx(
        "relative flex cursor-pointer flex-col overflow-hidden rounded-md border-2 has-focus-visible:outline-2 has-focus-visible:outline-focus has-focus-visible:outline-offset-2",
        on ? "border-text-primary" : "border-border hover:border-border-strong",
      )}
    >
      <input type="radio" name="theme" value={theme} checked={on} onChange={onPick} className="sr-only" />
      <PreviewFrame
        state={state}
        width={390}
        height={560}
        title={themeName(theme, locale)}
        className="pointer-events-none aspect-[390/560] border-0 border-b"
      />
      <span className="flex items-center justify-between gap-2 px-3 pt-3 text-title">
        {themeName(theme, locale)}
        {on && <Check aria-hidden size={18} />}
      </span>
      <span className="px-3 pt-1 pb-3 text-caption text-text-secondary">{themeNote(theme, locale)}</span>
    </label>
  );
}

function ColorField({
  loading = false,
  label,
  help,
  value,
  disabled,
  onChange,
}: {
  loading?: boolean;
  label: string;
  help?: string;
  value: string;
  disabled: boolean;
  onChange: (value: string) => void;
}) {
  const t = useTranslations("appearance");
  if (loading) return <Waiting label={label} help={help} />;
  return (
    <Field label={label} help={help} error={HEX.test(value) ? undefined : t("hex")}>
      {(p) => (
        <span className="flex gap-2">
          <input
            type="color"
            aria-label={`${label}: ${t("pick")}`}
            value={HEX.test(value) ? value : "#000000"}
            disabled={disabled}
            onChange={(e) => onChange(e.target.value.toLowerCase())}
            className="tap w-14 shrink-0 cursor-pointer rounded-sm border border-border-strong bg-surface p-1"
          />
          <input
            {...p}
            value={value}
            spellCheck={false}
            maxLength={7}
            disabled={disabled}
            onChange={(e) => onChange(e.target.value.trim().toLowerCase())}
            className={cx(p.className, "font-mono")}
          />
        </span>
      )}
    </Field>
  );
}

function Verdict({
  loading = false,
  bad,
  pick,
  onFix,
  disabled,
}: {
  loading?: boolean;
  bad: ReturnType<typeof failures>;
  pick: () => string;
  onFix: (color: string) => void;
  disabled: boolean;
}) {
  const t = useTranslations("appearance");
  const locale = useLocale() as "sw" | "en";
  const format = useFormatter();
  const better = useMemo(() => (bad.length ? pick() : ""), [bad, pick]);
  if (loading)
    return (
      <p className="text-label">
        <Bone className="w-56" />
      </p>
    );
  if (bad.length === 0)
    return (
      <p className="flex items-center gap-2 text-label text-success" role="status">
        <CircleCheck aria-hidden size={18} /> {t("passes")}
      </p>
    );
  return (
    <div role="status" className="flex flex-col gap-3 rounded-sm bg-warning-soft p-3 text-warning">
      <p className="flex items-center gap-2 text-label">
        <TriangleAlert aria-hidden size={18} className="shrink-0" /> {t("fails", { count: bad.length })}
      </p>
      <ul className="flex flex-col gap-1 text-caption">
        {bad.slice(0, 4).map((f) => (
          <li key={`${f.theme}${f.scheme}${f.fg}${f.bg}`}>
            {themeName(f.theme, locale)} · {f.fg} / {f.bg}:{" "}
            <span className="tabular-nums">
              {format.number(f.ratio, { maximumFractionDigits: 2 })}:1 ({t("needs")} {f.min}:1)
            </span>
          </li>
        ))}
      </ul>
      <Button variant="secondary" className="self-start" disabled={disabled} onClick={() => onFix(better)}>
        <span
          aria-hidden
          className="size-5 rounded-full border border-border"
          style={{ background: better }}
        />
        {t("useNearest", { color: better })}
      </Button>
    </div>
  );
}

const SAMPLES = [
  ["on-brand", "brand", "button"],
  ["brand-text", "surface-sunken", "text"],
  ["wordmark", "masthead-bg", "logo"],
  ["nav-active", "nav-bg", "nav"],
  ["signal-breaking-label", "signal-breaking-bg", "breaking"],
] as const;
/** The pairs people meet most, as they will look, with what they measure. */
function Pairs({
  loading,
  theme,
  color,
  dark,
}: {
  loading: boolean;
  theme: ThemeKey;
  color: string;
  dark: string;
}) {
  const t = useTranslations("appearance");
  const format = useFormatter();
  return (
    <div className="grid gap-3 sm:grid-cols-2">
      {(["light", "dark"] as const).map((scheme) => {
        const tokens = derive(theme, scheme, color, dark);
        const all = check(theme, scheme, tokens).length === 0;
        return (
          <section
            key={scheme}
            aria-label={t(scheme)}
            className="overflow-hidden rounded-sm border border-border"
          >
            <h3 className="flex items-center justify-between border-border border-b px-3 py-2 text-label">
              {t(scheme)} {all && <CircleCheck aria-hidden size={16} className="text-success" />}
            </h3>
            <ul>
              {SAMPLES.map(([fg, bg, name]) => (
                <li
                  key={name}
                  className="flex items-center justify-between px-3 py-2 text-caption"
                  style={loading ? undefined : { color: tokens[fg], background: tokens[bg] }}
                >
                  <span className="font-semibold">
                    {loading ? <Bone className="w-16" /> : t(`sample.${name}`)}
                  </span>
                  <span className="tabular-nums">
                    {!loading &&
                      `${format.number(contrast(tokens[fg] ?? "", tokens[bg] ?? ""), { maximumFractionDigits: 1 })}:1`}
                  </span>
                </li>
              ))}
            </ul>
          </section>
        );
      })}
    </div>
  );
}

const base64 = (file: File) =>
  new Promise<string>((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result).split(",")[1] ?? "");
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(file);
  });
function LogoSlot({
  loading,
  slot,
  logo,
  fallback,
  name,
  disabled,
  onChange,
}: {
  loading: boolean;
  slot: Slot;
  logo: Logo | null;
  fallback: Logo | null;
  name: string;
  disabled: boolean;
  onChange: (logo: (Logo & { id: string }) | null, white: Logo | null) => void;
}) {
  const t = useTranslations("appearance");
  const input = useRef<HTMLInputElement>(null);
  const [pending, setPending] = useState(false);
  const [problem, setProblem] = useState<unknown>(null);
  const show = logo ?? fallback;
  const square = slot === "symbol";
  const src = show ? show.svg || show.png[square ? "2x" : "3x"] : "";
  async function upload(file: File | undefined) {
    if (!file) return;
    setPending(true);
    setProblem(null);
    try {
      if (file.size > 1_000_000) throw new ApiError(400, "logo_too_large", "");
      const content = await base64(file);
      const r = await call(() =>
        client.POST("/api/v1/brand/logos", { body: { kind: square ? "symbol" : "wordmark", content } }),
      );
      onChange(r.logo, r.white);
    } catch (err) {
      setProblem(err);
    } finally {
      setPending(false);
      if (input.current) input.current.value = "";
    }
  }
  const grounds =
    slot === "wordmark_light" ? ["#ffffff"] : slot === "wordmark_dark" ? ["#0b0b0c"] : ["#ffffff", "#0b0b0c"];
  return (
    <li className="flex flex-col gap-2">
      <span className="text-label">{t(`slot.${slot}`)}</span>
      <div className={cx("grid gap-2", grounds.length > 1 && "grid-cols-2")}>
        {grounds.map((ground) => (
          <span
            key={ground}
            className="grid h-24 place-items-center rounded-sm border border-border px-6"
            style={loading ? undefined : { background: ground }}
          >
            {loading ? (
              <Bone className="w-32" />
            ) : src ? (
              <img
                src={src}
                alt={t(`slot.${slot}`)}
                className={square ? "size-14" : "h-8 w-auto max-w-full object-contain"}
              />
            ) : (
              <span
                className={cx("font-serif", square ? "text-headline-m" : "text-headline-s")}
                style={{ color: ground === "#ffffff" ? color : "#ffffff" }}
              >
                {square ? name.slice(0, 1) : name}
              </span>
            )}
          </span>
        ))}
      </div>
      <p className="text-caption text-text-secondary">{logo ? t(`help.${slot}`) : t(`absent.${slot}`)}</p>
      <FormError error={problem} />
      {loading && <span aria-hidden className="tap bone w-28" />}
      {!disabled && (
        <div className="flex gap-2">
          <input
            ref={input}
            type="file"
            accept=".svg,.png,image/svg+xml,image/png"
            className="sr-only"
            tabIndex={-1}
            aria-label={t(`slot.${slot}`)}
            onChange={(e) => upload(e.target.files?.[0])}
          />
          <Button
            variant="secondary"
            pending={pending}
            onClick={() => input.current?.click()}
            aria-label={`${t(logo ? "replace" : "upload")}: ${t(`slot.${slot}`)}`}
          >
            <Upload aria-hidden size={18} /> {t(logo ? "replace" : "upload")}
          </Button>
          {logo && (
            <Button
              variant="ghost"
              onClick={() => onChange(null, null)}
              aria-label={`${t("remove")}: ${t(`slot.${slot}`)}`}
            >
              {t("remove")}
            </Button>
          )}
        </div>
      )}
    </li>
  );
}

function LivePreview({
  theme,
  color,
  dark,
  brand,
  locale,
}: {
  theme: ThemeKey;
  color: string;
  dark: string;
  brand: Shown;
  locale: "sw" | "en";
}) {
  const t = useTranslations("appearance");
  const [screen, setScreen] = useState<PreviewScreen>("home");
  const [scheme, setScheme] = useState<Scheme>("light");
  const vars = useVariables(theme, scheme, color, dark);
  const state = useMemo(
    () => ({ screen, scheme, locale, variables: vars, brand }),
    [screen, scheme, locale, vars, brand],
  );
  const chip = (on: boolean) =>
    cx(
      "tap inline-flex items-center rounded-full px-4 text-label",
      on ? "bg-text-primary text-bg" : "border border-border text-text-secondary hover:bg-surface-sunken",
    );
  return (
    <Card className="flex flex-col gap-4 xl:sticky xl:top-6">
      <h2 className="text-headline-s">{t("preview")}</h2>
      <div className="flex flex-wrap gap-2">
        {PREVIEW_SCREENS.map((s) => (
          <button
            key={s}
            type="button"
            aria-pressed={s === screen}
            className={chip(s === screen)}
            onClick={() => setScreen(s)}
          >
            {t(`screen.${s}`)}
          </button>
        ))}
        <span className="ml-auto flex gap-2">
          {(["light", "dark"] as const).map((s) => (
            <button
              key={s}
              type="button"
              aria-pressed={s === scheme}
              className={chip(s === scheme)}
              onClick={() => setScheme(s)}
            >
              {t(s)}
            </button>
          ))}
        </span>
      </div>
      <div className="grid items-start gap-4 sm:grid-cols-[minmax(0,1fr)_minmax(0,1.9fr)]">
        <PreviewFrame state={state} {...PHONE} title={t("phone")} className="aspect-[390/844] rounded-lg" />
        <PreviewFrame state={state} {...DESK} title={t("desktop")} className="aspect-[1280/844] rounded-md" />
      </div>
      <p className="text-caption text-text-secondary">{t("previewNote")}</p>
    </Card>
  );
}

function History({
  version,
  disabled,
  onRestore,
}: {
  version?: number;
  disabled: boolean;
  onRestore: (number: number) => void;
}) {
  const t = useTranslations("appearance");
  const locale = useLocale() as "sw" | "en";
  const format = useFormatter();
  const { data } = useQuery({
    queryKey: [...KEY, "versions", version],
    queryFn: () => call(() => client.GET("/api/v1/brand/versions")),
    enabled: version !== undefined,
  });
  if (data?.results.length === 0) return null;
  return (
    <Card>
      <h2 className="mb-2 text-headline-s">{t("history")}</h2>
      <ul className="divide-y divide-border">
        {(data?.results ?? [undefined, undefined]).map((v, i) => (
          <li key={v?.number ?? i} className="flex items-center gap-3 py-3">
            {v ? (
              <>
                <span
                  aria-hidden
                  className="size-8 shrink-0 rounded-full border border-border"
                  style={{ background: v.data.appearance.color }}
                />
                <div className="min-w-0 flex-1">
                  <p className="text-label">
                    {v.number}. {v.data.identity.brand_name} ·{" "}
                    {themeName(v.data.appearance.theme as ThemeKey, locale)}
                  </p>
                  <p className="text-caption text-text-secondary">
                    {format.dateTime(new Date(v.published_at), { dateStyle: "medium", timeStyle: "short" })}
                    {v.published_by && ` · ${v.published_by.display_name}`}
                    {v.note && ` · ${v.note}`}
                  </p>
                </div>
                {v.number === version ? (
                  <span className="text-caption text-text-secondary">{t("current")}</span>
                ) : (
                  <Button
                    variant="secondary"
                    disabled={disabled}
                    onClick={() => onRestore(v.number)}
                    aria-label={`${t("restore")} ${v.number}`}
                  >
                    <RotateCcw aria-hidden size={16} /> {t("restore")}
                  </Button>
                )}
              </>
            ) : (
              <div className="flex-1">
                <p className="text-label">
                  <Bone className="w-48" />
                </p>
                <p className="text-caption">
                  <Bone className="w-64" />
                </p>
              </div>
            )}
          </li>
        ))}
      </ul>
    </Card>
  );
}
