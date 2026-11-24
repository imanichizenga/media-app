"use client";
import type { Schemas } from "@news/api-client/admin";
import { useQueryClient } from "@tanstack/react-query";
import { useTranslations } from "next-intl";
import { type FormEvent, useState } from "react";
import {
  Badge,
  Bone,
  Button,
  Card,
  Dialog,
  Empty,
  ErrorState,
  FormError,
  PageHeader,
  TextField,
} from "@/components/ui";
import { call, client } from "@/lib/api";
import { keys, usePaged, useSession, useTime } from "@/lib/queries";

type Decision = { row: Schemas["Approval"]; decision: "approve" | "reject" };
export default function Approvals() {
  const t = useTranslations("approvals");
  const c = useTranslations("common");
  const time = useTime();
  const queries = useQueryClient();
  const { data: session } = useSession();
  const [status, setStatus] = useState("pending");
  const [open, setOpen] = useState<Decision | null>(null);
  const [error, setError] = useState<unknown>(null);
  const [pending, setPending] = useState(false);
  const list = usePaged(keys.approvals(status), (cursor) =>
    call(() =>
      client.GET("/api/v1/approvals", { params: { query: { ...(status ? { status } : {}), cursor } } }),
    ),
  );
  async function decide(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!open) return;
    const note = String(new FormData(e.currentTarget).get("note"));
    setPending(true);
    setError(null);
    try {
      await call(() =>
        client.POST("/api/v1/approvals/{approval_id}/{decision}", {
          params: { path: { approval_id: open.row.id, decision: open.decision } },
          body: { note },
        }),
      );
      setOpen(null);
      await queries.invalidateQueries({ queryKey: ["approvals"] });
    } catch (err) {
      setError(err);
    } finally {
      setPending(false);
    }
  }
  return (
    <>
      <PageHeader
        title={t("title")}
        lead={t("lead")}
        actions={
          <fieldset className="flex gap-2">
            <legend className="sr-only">{t("filter")}</legend>
            {["pending", ""].map((s) => (
              <Button
                key={s}
                variant={status === s ? "primary" : "secondary"}
                aria-pressed={status === s}
                onClick={() => setStatus(s)}
              >
                {t(s ? "pending" : "all")}
              </Button>
            ))}
          </fieldset>
        }
      />
      {list.error ? (
        <ErrorState error={list.error} retry={list.refetch} />
      ) : list.rows?.length === 0 ? (
        <Card>
          <Empty title={t("empty")} body={t("emptyBody")} />
        </Card>
      ) : (
        <ul className="flex flex-col gap-3">
          {list.rows
            ? list.rows.map((a) => {
                const own = a.requested_by.id === session?.user.id;
                return (
                  <li key={a.id}>
                    <Card className="flex flex-wrap items-center justify-between gap-4">
                      <div className="min-w-0">
                        <p className="text-title">{a.summary}</p>
                        <p className="text-caption text-text-secondary">
                          {a.requested_by.display_name} · {time(a.created_at)}
                        </p>
                        {a.reason && <p className="text-caption">{a.reason}</p>}
                      </div>
                      {a.status === "pending" ? (
                        <div className="flex gap-2">
                          <Button
                            variant="secondary"
                            onClick={() => {
                              setError(null);
                              setOpen({ row: a, decision: "reject" });
                            }}
                          >
                            {t(own ? "cancel" : "reject")}
                          </Button>
                          {!own && (
                            <Button
                              onClick={() => {
                                setError(null);
                                setOpen({ row: a, decision: "approve" });
                              }}
                            >
                              {t("approve")}
                            </Button>
                          )}
                        </div>
                      ) : (
                        <Badge tone={a.status === "executed" ? "success" : "neutral"}>
                          {t(`status.${a.status}`)}
                        </Badge>
                      )}
                    </Card>
                  </li>
                );
              })
            : Array.from({ length: 5 }, (_, i) => (
                // biome-ignore lint/suspicious/noArrayIndexKey: static placeholders
                <li key={i} data-skeleton="row">
                  <Card className="flex flex-wrap items-center justify-between gap-4">
                    <div>
                      <p className="text-title">
                        <Bone className="w-56" />
                      </p>
                      <p className="text-caption">
                        <Bone className="w-40" />
                      </p>
                    </div>
                    <span className="tap bone w-40" />
                  </Card>
                </li>
              ))}
        </ul>
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
        open={open !== null}
        onClose={() => setOpen(null)}
        title={open ? t(`${open.decision}Title`) : ""}
        description={open?.row.summary}
      >
        <form onSubmit={decide} className="flex flex-col gap-4">
          <FormError error={error} />
          {open && (
            <pre className="overflow-x-auto rounded-sm bg-surface-sunken p-3 font-mono text-caption">
              {JSON.stringify(open.row.payload, null, 2)}
            </pre>
          )}
          <TextField label={t("note")} name="note" required={open?.decision === "reject"} maxLength={500} />
          <Button
            type="submit"
            variant={open?.decision === "approve" ? "primary" : "danger"}
            pending={pending}
          >
            {t(open?.decision === "approve" ? "approve" : "reject")}
          </Button>
        </form>
      </Dialog>
    </>
  );
}
