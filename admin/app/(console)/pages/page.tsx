"use client";
import { useQuery } from "@tanstack/react-query";
import { ChevronRight } from "lucide-react";
import Link from "next/link";
import { useFormatter, useTranslations } from "next-intl";
import { Bone, Card, ErrorState, PageHeader } from "@/components/ui";
import { call, client } from "@/lib/api";
import { keys } from "@/lib/queries";

const KEYS = ["about", "editorial-policy", "corrections", "contact", "privacy", "terms"];

/** The publisher's own pages: legal and editorial texts are content, never code (ADR-0045). */
export default function PagesPage() {
  const t = useTranslations("pages");
  const format = useFormatter();
  const { data, error, refetch } = useQuery({
    queryKey: keys.pages,
    queryFn: () => call(() => client.GET("/api/v1/pages")),
  });
  return (
    <>
      <PageHeader title={t("title")} lead={t("lead")} />
      <Card>
        {error && !data ? (
          <ErrorState error={error} retry={refetch} />
        ) : (
          <ul className="divide-y divide-border">
            {(data ?? KEYS.map((key) => ({ key, loading: true as const }))).map((p) => (
              <li key={p.key}>
                <Link
                  href={`/pages/${p.key}`}
                  className="tap flex items-center gap-4 py-3 hover:bg-surface-sunken"
                >
                  <span className="min-w-0 flex-1">
                    <span className="block text-title">{t(`key.${p.key}` as never)}</span>
                    <span className="block text-caption text-text-secondary">
                      {"loading" in p ? (
                        <Bone className="w-40" />
                      ) : p.published_at ? (
                        t("publishedOn", {
                          n: p.published_number ?? 0,
                          when: format.dateTime(new Date(p.published_at), {
                            dateStyle: "medium",
                            timeStyle: "short",
                          }),
                        })
                      ) : p.version ? (
                        t("draftOnly")
                      ) : (
                        t("empty")
                      )}
                    </span>
                  </span>
                  <ChevronRight aria-hidden size={18} className="text-text-secondary" />
                </Link>
              </li>
            ))}
          </ul>
        )}
      </Card>
    </>
  );
}
