"use client";
import Link from "next/link";
import { useLocale, useTranslations } from "next-intl";
import { IntegrationStatus } from "@/components/integration-status";
import { Bone, ErrorState, PageHeader } from "@/components/ui";
import { useIntegrations, useTime } from "@/lib/queries";

const CARD = "flex h-full flex-col gap-2 rounded-md border border-border bg-surface p-5";
export default function Integrations() {
  const t = useTranslations("integrations");
  const en = useLocale() === "en";
  const time = useTime();
  const { data, error, refetch } = useIntegrations();
  if (error && !data) return <ErrorState error={error} retry={refetch} />;
  return (
    <>
      <PageHeader title={t("title")} lead={t("lead")} />
      <ul className="grid gap-4 sm:grid-cols-2">
        {data
          ? data.map((i) => (
              <li key={i.provider}>
                <Link
                  href={`/integrations/${i.provider}`}
                  prefetch={false}
                  className={`${CARD} hover:border-border-strong`}
                >
                  <span className="flex items-start justify-between gap-3">
                    <span className="text-title">{i.name}</span>
                    <IntegrationStatus status={i.status} />
                  </span>
                  <span className="line-clamp-2 min-h-12 text-text-secondary">
                    {en ? i.description_en : i.description_sw}
                  </span>
                  <span className="text-caption text-text-secondary">
                    {t("lastTest")}: {time(i.last_tested_at)}
                  </span>
                </Link>
              </li>
            ))
          : Array.from({ length: 4 }, (_, n) => (
              // biome-ignore lint/suspicious/noArrayIndexKey: static placeholders
              <li key={n} data-skeleton="card">
                <div className={CARD}>
                  <span className="flex items-start justify-between gap-3">
                    <span className="text-title">
                      <Bone className="w-40" />
                    </span>
                    <Bone className="w-20 text-caption" />
                  </span>
                  <span className="min-h-12">
                    <Bone className="w-full" />
                  </span>
                  <span className="text-caption">
                    <Bone className="w-36" />
                  </span>
                </div>
              </li>
            ))}
      </ul>
    </>
  );
}
