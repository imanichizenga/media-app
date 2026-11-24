"use client";
import { ChevronRight } from "lucide-react";
import Link from "next/link";
import { useLocale, useTranslations } from "next-intl";
import type { ReactNode } from "react";
import { EventName } from "@/components/event-name";
import { IntegrationStatus } from "@/components/integration-status";
import { Bone, Card, Empty, ErrorState, PageHeader } from "@/components/ui";
import { call, client } from "@/lib/api";
import { keys, useCan, useIntegrations, useMySecurity, usePaged, useSession, useTime } from "@/lib/queries";

const ROW = "flex min-h-11 items-center justify-between gap-4 py-2";
type PanelProps = { title: string; href: string; className?: string; children: ReactNode };
function Panel({ title, href, className, children }: PanelProps) {
  return (
    <Card className={className}>
      <h2 className="text-headline-s">
        <Link
          href={href}
          prefetch={false}
          className="tap inline-flex items-center gap-1 hover:text-brand-text"
        >
          {title}
          <ChevronRight aria-hidden size={18} />
        </Link>
      </h2>
      <ul className="mt-1 divide-y divide-border">{children}</ul>
    </Card>
  );
}
const Bones = ({ n }: { n: number }) =>
  Array.from({ length: n }, (_, i) => (
    // biome-ignore lint/suspicious/noArrayIndexKey: static placeholders
    <li key={i} className={ROW} data-skeleton="row">
      <Bone className="w-40" />
      <Bone className="w-20" />
    </li>
  ));

export default function Dashboard() {
  const t = useTranslations("dashboard");
  const locale = useLocale();
  const time = useTime();
  const can = useCan();
  const { data: session } = useSession();
  const integrations = useIntegrations(can("integrations.view"));
  const approvals = usePaged(
    keys.approvals("pending"),
    (cursor) =>
      call(() => client.GET("/api/v1/approvals", { params: { query: { status: "pending", cursor } } })),
    can("approvals.decide"),
  );
  const security = useMySecurity();
  const events = security.data?.recent_events.slice(0, 5);
  return (
    <>
      <PageHeader
        title={session ? t("hello", { name: session.user.display_name }) : t("title")}
        lead={t("lead")}
      />
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
        {(!session || can("integrations.view")) && (
          <Panel title={t("health")} href="/integrations">
            {integrations.error ? (
              <li>
                <ErrorState error={integrations.error} retry={integrations.refetch} />
              </li>
            ) : (
              (integrations.data?.map((i) => (
                <li key={i.provider} className={ROW}>
                  <span className="min-w-0 truncate">{i.name}</span>
                  <IntegrationStatus status={i.status} />
                </li>
              )) ?? <Bones n={4} />)
            )}
          </Panel>
        )}
        {(!session || can("approvals.decide")) && (
          <Panel title={t("approvals")} href="/approvals">
            {approvals.error ? (
              <li>
                <ErrorState error={approvals.error} retry={approvals.refetch} />
              </li>
            ) : approvals.rows?.length === 0 ? (
              <li>
                <Empty title={t("noApprovals")} />
              </li>
            ) : (
              (approvals.rows?.slice(0, 5).map((a) => (
                <li key={a.id} className={ROW}>
                  <span className="min-w-0 truncate">{a.summary}</span>
                  <span className="shrink-0 text-caption text-text-secondary">
                    {a.requested_by.display_name}
                  </span>
                </li>
              )) ?? <Bones n={4} />)
            )}
          </Panel>
        )}
        <Panel title={t("activity")} href="/security" className="md:col-span-full">
          {security.error ? (
            <li>
              <ErrorState error={security.error} retry={security.refetch} />
            </li>
          ) : (
            (events?.map((e) => (
              <li key={e.id} className={ROW}>
                <span className="min-w-0 truncate">
                  <EventName kind={e.kind} />
                </span>
                <time
                  dateTime={e.created_at}
                  lang={locale}
                  className="shrink-0 text-caption text-text-secondary"
                >
                  {time(e.created_at)}
                </time>
              </li>
            )) ?? <Bones n={5} />)
          )}
        </Panel>
      </div>
    </>
  );
}
