"use client";
import type { Schemas } from "@news/api-client/admin";
import { Download, ShieldCheck } from "lucide-react";
import { useTranslations } from "next-intl";
import { useState } from "react";
import {
  ActionBone,
  BoneRows,
  Button,
  Card,
  Dialog,
  Empty,
  ErrorState,
  FormError,
  Notice,
  PageHeader,
  Row,
  Table,
  Td,
  TextField,
} from "@/components/ui";
import { call, client } from "@/lib/api";
import { useCan, usePaged, useSession, useTime } from "@/lib/queries";

type Entry = Schemas["Audit"];
function Diff({ entry }: { entry: Entry }) {
  const t = useTranslations("audit");
  const before = (entry.before ?? {}) as Record<string, unknown>;
  const after = (entry.after ?? {}) as Record<string, unknown>;
  const names = [...new Set([...Object.keys(before), ...Object.keys(after)])];
  if (!names.length) return null;
  return (
    <Table label={t("changes")} head={[t("field"), t("before"), t("after")]}>
      {names.map((n) => (
        <Row key={n}>
          <Td>{n}</Td>
          <Td className="font-mono text-caption break-all">
            {n in before ? JSON.stringify(before[n]) : "—"}
          </Td>
          <Td className="font-mono text-caption break-all">{n in after ? JSON.stringify(after[n]) : "—"}</Td>
        </Row>
      ))}
    </Table>
  );
}
export default function Audit() {
  const t = useTranslations("audit");
  const c = useTranslations("common");
  const time = useTime();
  const can = useCan();
  const { data: session } = useSession();
  const [action, setAction] = useState("");
  const [entry, setEntry] = useState<Entry | null>(null);
  const [report, setReport] = useState<Schemas["ChainReport"] | null>(null);
  const [pending, setPending] = useState("");
  const [problem, setProblem] = useState<unknown>(null);
  const list = usePaged(["audit", action], (cursor) =>
    call(() => client.GET("/api/v1/audit", { params: { query: { ...(action ? { action } : {}), cursor } } })),
  );
  async function act(name: string, fn: () => Promise<void>) {
    setPending(name);
    setProblem(null);
    await fn().catch(setProblem);
    setPending("");
  }
  const verify = () =>
    act("verify", async () => setReport(await call(() => client.POST("/api/v1/audit/verify"))));
  const download = () =>
    act("export", async () => {
      const csv = await call(() =>
        client.POST("/api/v1/audit/export", { params: { query: action ? { action } : {} }, parseAs: "blob" }),
      );
      const link = Object.assign(document.createElement("a"), {
        href: URL.createObjectURL(csv as Blob),
        download: "audit-log.csv",
      });
      link.click();
      URL.revokeObjectURL(link.href);
    });
  return (
    <>
      <PageHeader
        title={t("title")}
        lead={t("lead")}
        actions={
          <>
            <Button variant="secondary" pending={pending === "verify"} onClick={verify}>
              <ShieldCheck aria-hidden size={18} />
              {t("verify")}
            </Button>
            {session ? (
              can("audit.export") && (
                <Button variant="secondary" pending={pending === "export"} onClick={download}>
                  <Download aria-hidden size={18} />
                  {t("export")}
                </Button>
              )
            ) : (
              <ActionBone />
            )}
          </>
        }
      />
      <div className="mb-4 flex flex-col gap-3">
        <FormError error={problem} />
        {report &&
          (report.ok ? (
            <Notice tone="success">
              {t("intact", { count: report.checked, anchors: report.anchors_checked })}
            </Notice>
          ) : (
            <Notice tone="danger">{t("broken", { count: report.problems.length })}</Notice>
          ))}
        <div className="max-w-xs">
          <TextField
            label={t("filterAction")}
            placeholder="integration."
            defaultValue=""
            onChange={(e) => setAction(e.target.value.trim())}
          />
        </div>
      </div>
      {list.error ? (
        <ErrorState error={list.error} retry={list.refetch} />
      ) : list.rows?.length === 0 ? (
        <Card>
          <Empty title={t("empty")} />
        </Card>
      ) : (
        <Table label={t("title")} head={["#", t("when"), t("who"), t("action"), t("target"), ""]}>
          {list.rows ? (
            list.rows.map((e) => (
              <Row key={e.seq}>
                <Td className="tabular-nums">{e.seq}</Td>
                <Td className="whitespace-nowrap text-text-secondary">{time(e.occurred_at)}</Td>
                <Td>{e.actor_label}</Td>
                <Td className="font-mono text-caption">{e.action}</Td>
                <Td>{e.target_label}</Td>
                <Td>
                  <Button
                    variant="ghost"
                    aria-label={t("openSeq", { seq: e.seq })}
                    onClick={() => setEntry(e)}
                  >
                    {c("open")}
                  </Button>
                </Td>
              </Row>
            ))
          ) : (
            <BoneRows action widths={["w-6", "w-32", "w-28", "w-36", "w-28", "w-16"]} rows={10} />
          )}
        </Table>
      )}
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
      <Dialog
        open={entry !== null}
        onClose={() => setEntry(null)}
        title={entry ? `#${entry.seq} ${entry.action}` : ""}
      >
        {entry && (
          <div className="flex flex-col gap-4">
            <dl className="grid grid-cols-[auto_minmax(0,1fr)] gap-x-4 gap-y-1 text-caption">
              {(
                [
                  [t("who"), entry.actor_label],
                  [t("when"), time(entry.occurred_at)],
                  ["IP", entry.ip],
                  [t("device"), entry.user_agent],
                  [c("reason"), entry.reason],
                  [t("approvedBy"), entry.approved_by_id],
                  ["Hash", entry.hash],
                ] as const
              )
                .filter(([, v]) => v)
                .map(([k, v]) => (
                  <div key={k} className="contents">
                    <dt className="text-text-secondary">{k}</dt>
                    <dd className="break-all">{v}</dd>
                  </div>
                ))}
            </dl>
            <Diff entry={entry} />
          </div>
        )}
      </Dialog>
    </>
  );
}
