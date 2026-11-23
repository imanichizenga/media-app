import { useTranslations } from "next-intl";
import { Badge, type Tone } from "./ui";

const TONE: Record<string, Tone> = {
  active: "success",
  failing: "danger",
  draft: "warning",
  unconfigured: "neutral",
};
export function IntegrationStatus({ status }: { status: string }) {
  const t = useTranslations("integrations.status");
  return <Badge tone={TONE[status] ?? "neutral"}>{t(status as never)}</Badge>;
}
