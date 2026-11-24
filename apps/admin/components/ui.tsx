"use client";
import * as ui from "@news/ui/primitives";
import { CircleAlert, CloudOff } from "lucide-react";
import { useTranslations } from "next-intl";
import type { ComponentProps } from "react";
import { ApiError } from "@/lib/api";

// The shared components, plus the few that speak: those need this app's catalogues.
export * from "@news/ui/primitives";

export function useErrorText() {
  const t = useTranslations("errors");
  return (error: unknown) => {
    if (!(error instanceof ApiError)) return t("unavailable");
    if (error.code === "rate_limited")
      return t("rate_limited", { seconds: Number(error.extra.retry_after ?? 60) });
    return t.has(error.code as never)
      ? t(error.code as never)
      : error.status >= 500
        ? t("unavailable")
        : error.detail || t("unavailable");
  };
}

export function ErrorState({ error, retry }: { error: unknown; retry?: () => void }) {
  const t = useTranslations("common");
  const text = useErrorText();
  const offline = error instanceof ApiError && error.code === "offline";
  return (
    <ui.Message
      icon={offline ? CloudOff : CircleAlert}
      title={text(error)}
      action={
        retry && (
          <ui.Button variant="secondary" onClick={retry}>
            {t("retry")}
          </ui.Button>
        )
      }
    />
  );
}

export function FormError({ error }: { error: unknown }) {
  const text = useErrorText();
  return error ? <ui.Notice tone="danger">{text(error)}</ui.Notice> : null;
}

export function Dialog(props: Omit<ComponentProps<typeof ui.Dialog>, "closeLabel">) {
  const t = useTranslations("common");
  return <ui.Dialog {...props} closeLabel={t("close")} />;
}
