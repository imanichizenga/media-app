import { useTranslations } from "next-intl";

/** Falls back to the raw kind, so an event added by a newer API is still shown. */
export function EventName({ kind }: { kind: string }) {
  const t = useTranslations("events");
  return <>{t.has(kind as never) ? t(kind as never) : kind.replaceAll("_", " ")}</>;
}
