"use client";
import { useTranslations } from "next-intl";
import { useState } from "react";
import { EventName } from "@/components/event-name";
import {
  Badge,
  BoneRows,
  Button,
  Card,
  Empty,
  ErrorState,
  PageHeader,
  Row,
  Table,
  Td,
} from "@/components/ui";
import { call, client } from "@/lib/api";
import { useCan, usePaged, useTime } from "@/lib/queries";

function AuthLog() {
  const t = useTranslations("logs");
  const c = useTranslations("common");
  const time = useTime();
  const list = usePaged(["logs", "auth"], (cursor) =>
    call(() => client.GET("/api/v1/logs/auth", { params: { query: { cursor } } })),
  );
  if (list.error) return <ErrorState error={list.error} retry={list.refetch} />;
  return (
    <>
      <Table label={t("auth")} head={[t("when"), t("event"), t("result"), t("who"), "IP", t("country")]}>
        {list.rows ? (
          list.rows.map((e) => (
            <Row key={e.id}>
              <Td className="whitespace-nowrap text-text-secondary">{time(e.created_at)}</Td>
              <Td>
                <EventName kind={e.kind} />
              </Td>
              <Td>
                <Badge tone={e.ok ? "success" : "danger"}>{t(e.ok ? "ok" : "failed")}</Badge>
              </Td>
              <Td>{e.user_name || "—"}</Td>
              <Td>{e.ip}</Td>
              <Td>{e.country || "—"}</Td>
            </Row>
          ))
        ) : (
          <BoneRows widths={["w-32", "w-32", "w-16", "w-28", "w-24", "w-8"]} />
        )}
      </Table>
      {list.hasNextPage && (
        <Button
          variant="secondary"
          className="mt-4"
          pending={list.isFetchingNextPage}
          onClick={() => list.fetchNextPage()}
        >
          {c("more")}
        </Button>
      )}
    </>
  );
}
function CallLog() {
  const t = useTranslations("logs");
  const c = useTranslations("common");
  const time = useTime();
  const list = usePaged(["logs", "calls"], (cursor) =>
    call(() => client.GET("/api/v1/logs/integrations", { params: { query: { cursor } } })),
  );
  if (list.error) return <ErrorState error={list.error} retry={list.refetch} />;
  if (list.rows?.length === 0)
    return (
      <Card>
        <Empty title={t("noCalls")} />
      </Card>
    );
  return (
    <>
      <Table
        label={t("calls")}
        head={[t("when"), t("provider"), t("operation"), t("result"), "ms", t("detail")]}
      >
        {list.rows ? (
          list.rows.map((e) => (
            <Row key={e.id}>
              <Td className="whitespace-nowrap text-text-secondary">{time(e.created_at)}</Td>
              <Td>{e.provider}</Td>
              <Td className="font-mono text-caption">{e.operation}</Td>
              <Td>
                <Badge tone={e.ok ? "success" : "danger"}>{t(e.ok ? "ok" : "failed")}</Badge>
              </Td>
              <Td className="tabular-nums">{e.latency_ms}</Td>
              <Td className="max-w-sm text-caption break-words">{e.detail}</Td>
            </Row>
          ))
        ) : (
          <BoneRows widths={["w-32", "w-24", "w-32", "w-16", "w-10", "w-40"]} />
        )}
      </Table>
      {list.hasNextPage && (
        <Button
          variant="secondary"
          className="mt-4"
          pending={list.isFetchingNextPage}
          onClick={() => list.fetchNextPage()}
        >
          {c("more")}
        </Button>
      )}
    </>
  );
}
export default function Logs() {
  const t = useTranslations("logs");
  const can = useCan();
  const [tab, setTab] = useState<"auth" | "calls">("auth");
  return (
    <>
      <PageHeader title={t("title")} lead={t("lead")} />
      <div role="tablist" aria-label={t("title")} className="mb-4 flex gap-2">
        {(["auth", "calls"] as const)
          .filter((k) => k === "auth" || can("logs.view"))
          .map((k) => (
            <button
              key={k}
              type="button"
              role="tab"
              id={`tab-${k}`}
              aria-selected={tab === k}
              aria-controls="log-panel"
              onClick={() => setTab(k)}
              className={`tap rounded-sm px-4 text-label ${tab === k ? "bg-brand-soft text-brand-text" : "text-text-secondary hover:bg-surface-sunken"}`}
            >
              {t(k)}
            </button>
          ))}
      </div>
      <div role="tabpanel" id="log-panel" aria-labelledby={`tab-${tab}`}>
        {tab === "auth" ? <AuthLog /> : <CallLog />}
      </div>
    </>
  );
}
