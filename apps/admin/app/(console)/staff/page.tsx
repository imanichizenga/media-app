"use client";
import type { Schemas } from "@news/api-client/admin";
import { useQueryClient } from "@tanstack/react-query";
import { Copy, UserPlus } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { type FormEvent, useState } from "react";
import {
  ActionBone,
  Badge,
  BoneRows,
  Button,
  Dialog,
  Email,
  ErrorState,
  Field,
  FormError,
  Notice,
  PageHeader,
  Row,
  Table,
  Td,
  TextField,
} from "@/components/ui";
import { call, client } from "@/lib/api";
import { keys, useCan, useRoles, useSession, useStaff, useTime } from "@/lib/queries";

type Open = { kind: "invite" } | { kind: "member"; id: string } | null;
export default function Staff() {
  const t = useTranslations("staff");
  const c = useTranslations("common");
  const en = useLocale() === "en";
  const time = useTime();
  const can = useCan();
  const queries = useQueryClient();
  const { data: session } = useSession();
  const { data, error, refetch } = useStaff();
  const roles = useRoles();
  const [open, setOpen] = useState<Open>(null);
  const [pending, setPending] = useState("");
  const [problem, setProblem] = useState<unknown>(null);
  const [result, setResult] = useState<Schemas["LinkResult"] | null>(null);
  const [notice, setNotice] = useState("");
  if (error && !data) return <ErrorState error={error} retry={refetch} />;

  async function act(name: string, action: () => Promise<unknown>, message = "") {
    setPending(name);
    setProblem(null);
    setNotice("");
    try {
      await action();
      setNotice(message);
      await queries.invalidateQueries({ queryKey: keys.staff });
      return true;
    } catch (e) {
      setProblem(e);
      return false;
    } finally {
      setPending("");
    }
  }
  const show = (next: Open) => {
    setOpen(next);
    setProblem(null);
    setResult(null);
    setNotice("");
  };
  const invite = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    act("invite", async () =>
      setResult(
        await call(() =>
          client.POST("/api/v1/staff/invites", {
            body: {
              email: String(form.get("email")),
              grants: [{ role: String(form.get("role")), scope_type: "", scope_id: "" }],
            },
          }),
        ),
      ),
    );
  };
  const member = open?.kind === "member" ? data?.staff.find((s) => s.id === open.id) : undefined;
  const self = member?.id === session?.user.id;
  const options = roles.data?.roles.filter((r) => r.is_staff);
  const roleName = (key: string) => {
    const role = roles.data?.roles.find((r) => r.key === key);
    return role ? (en ? role.name_en : role.name_sw) : key;
  };
  const roleSelect = (control: object) => (
    <select name="role" {...control} required>
      {options?.map((r) => (
        <option key={r.key} value={r.key}>
          {en ? r.name_en : r.name_sw}
        </option>
      ))}
    </select>
  );
  const outcome = result && (
    <Notice tone={result.link ? "warning" : "success"}>
      {result.approval_required ? (
        t("sentForApproval")
      ) : result.emailed ? (
        t("emailed")
      ) : (
        <>
          <p>{t("linkOnce")}</p>
          <code
            data-testid="one-time-link"
            className="my-2 block font-mono text-caption break-all select-all"
          >
            {result.link}
          </code>
          <Button variant="secondary" onClick={() => navigator.clipboard.writeText(result.link ?? "")}>
            <Copy aria-hidden size={18} />
            {t("copyLink")}
          </Button>
        </>
      )}
    </Notice>
  );

  return (
    <>
      <PageHeader
        title={t("title")}
        lead={t("lead")}
        actions={
          session ? (
            can("staff.invite") && (
              <Button onClick={() => show({ kind: "invite" })}>
                <UserPlus aria-hidden size={18} />
                {t("invite")}
              </Button>
            )
          ) : (
            <ActionBone />
          )
        }
      />
      <Table label={t("title")} head={[t("name"), t("email"), t("roles"), t("mfa"), t("status"), ""]}>
        {data ? (
          data.staff.map((s) => (
            <Row key={s.id}>
              <Td>{s.display_name}</Td>
              <Td className="text-text-secondary">
                <Email value={s.email} />
              </Td>
              <Td>
                <span className="flex flex-wrap gap-1">
                  {s.roles.map((r) => (
                    <Badge key={r.assignment}>{en ? r.name_en : r.name_sw}</Badge>
                  ))}
                </span>
              </Td>
              <Td>
                <Badge tone={s.mfa ? "success" : "warning"}>{t(s.mfa ? "mfaOn" : "mfaOff")}</Badge>
              </Td>
              <Td>
                <Badge tone={s.status === "active" ? "success" : "danger"}>
                  {t(`state.${s.status}` as never)}
                </Badge>
              </Td>
              <Td>
                {can("staff.manage") && (
                  <Button
                    variant="ghost"
                    aria-label={t("manageName", { name: s.display_name })}
                    onClick={() => show({ kind: "member", id: s.id })}
                  >
                    {c("manage")}
                  </Button>
                )}
              </Td>
            </Row>
          ))
        ) : (
          <BoneRows action widths={["w-32", "w-48", "w-24", "w-16", "w-16", "w-16"]} />
        )}
      </Table>
      {data && data.invites.length > 0 && (
        <section className="mt-8">
          <h2 className="mb-3 text-headline-s">{t("pendingInvites")}</h2>
          <Table label={t("pendingInvites")} head={[t("email"), t("roles"), t("expires"), ""]}>
            {data.invites.map((i) => (
              <Row key={i.id}>
                <Td>
                  <Email value={i.email} />
                </Td>
                <Td>
                  <span className="flex flex-wrap gap-1">
                    {(i.grants as { role: string }[]).map((g) => (
                      <Badge key={g.role}>{roleName(g.role)}</Badge>
                    ))}
                  </span>
                </Td>
                <Td className="text-text-secondary">{time(i.expires_at)}</Td>
                <Td>
                  {can("staff.invite") && (
                    <Button
                      variant="ghost"
                      pending={pending === i.id}
                      onClick={() =>
                        act(i.id, () =>
                          call(() =>
                            client.DELETE("/api/v1/staff/invites/{invite_id}", {
                              params: { path: { invite_id: i.id } },
                            }),
                          ),
                        )
                      }
                    >
                      {t("revoke")}
                    </Button>
                  )}
                </Td>
              </Row>
            ))}
          </Table>
        </section>
      )}
      <Dialog
        open={open?.kind === "invite"}
        onClose={() => show(null)}
        title={t("invite")}
        description={t("inviteLead")}
      >
        {outcome ?? (
          <form onSubmit={invite} className="flex flex-col gap-4">
            <FormError error={problem} />
            <TextField label={t("email")} name="email" type="email" required />
            <Field label={t("role")}>{roleSelect}</Field>
            <Button type="submit" pending={pending === "invite"}>
              {t("sendInvite")}
            </Button>
          </form>
        )}
      </Dialog>
      <Dialog
        open={Boolean(member)}
        onClose={() => show(null)}
        title={member?.display_name ?? ""}
        description={member?.email}
      >
        {member && (
          <div className="flex flex-col gap-4">
            <FormError error={problem} />
            {notice && <Notice tone="success">{notice}</Notice>}
            {outcome}
            <ul className="divide-y divide-border">
              {member.roles.map((r) => (
                <li key={r.assignment} className="flex items-center justify-between gap-2">
                  {en ? r.name_en : r.name_sw}
                  {!self && (
                    <Button
                      variant="ghost"
                      pending={pending === r.assignment}
                      onClick={() =>
                        act(r.assignment ?? "", () =>
                          call(() =>
                            client.DELETE("/api/v1/assignments/{assignment_id}", {
                              params: { path: { assignment_id: r.assignment ?? "" } },
                            }),
                          ),
                        )
                      }
                    >
                      {t("removeRole")}
                    </Button>
                  )}
                </li>
              ))}
            </ul>
            {self ? (
              <p className="text-text-secondary">{t("notYourself")}</p>
            ) : (
              <>
                <form
                  className="flex flex-wrap items-end gap-2"
                  onSubmit={(e) => {
                    e.preventDefault();
                    const role = String(new FormData(e.currentTarget).get("role"));
                    act("grant", async () => {
                      const r = await call(() =>
                        client.POST("/api/v1/assignments", {
                          body: { user: member.id, role, scope_type: "", scope_id: "" },
                        }),
                      );
                      if (r.approval_required) setNotice(t("sentForApproval"));
                    });
                  }}
                >
                  <div className="min-w-40 flex-1">
                    <Field label={t("addRole")}>{roleSelect}</Field>
                  </div>
                  <Button type="submit" variant="secondary" pending={pending === "grant"}>
                    {c("add")}
                  </Button>
                </form>
                <div className="flex flex-col gap-2 border-t border-border pt-4">
                  <Button
                    variant="secondary"
                    pending={pending === "logout"}
                    onClick={() =>
                      act(
                        "logout",
                        () =>
                          call(() =>
                            client.POST("/api/v1/staff/{user_id}/logout", {
                              params: { path: { user_id: member.id } },
                            }),
                          ),
                        t("loggedOut"),
                      )
                    }
                  >
                    {t("forceLogout")}
                  </Button>
                  {[false, true].map((mfa) => (
                    <Button
                      key={String(mfa)}
                      variant="secondary"
                      pending={pending === `reset${mfa}`}
                      onClick={() =>
                        act(`reset${mfa}`, async () =>
                          setResult(
                            await call(() =>
                              client.POST("/api/v1/staff/{user_id}/reset", {
                                params: { path: { user_id: member.id } },
                                body: { reset_mfa: mfa },
                              }),
                            ),
                          ),
                        )
                      }
                    >
                      {t(mfa ? "resetMfa" : "resetPassword")}
                    </Button>
                  ))}
                </div>
                <form
                  className="flex flex-col gap-2 border-t border-border pt-4"
                  onSubmit={(e) => {
                    e.preventDefault();
                    const reason = String(new FormData(e.currentTarget).get("reason"));
                    act("status", () =>
                      call(() =>
                        client.POST("/api/v1/staff/{user_id}/status", {
                          params: { path: { user_id: member.id } },
                          body: { active: member.status !== "active", reason },
                        }),
                      ),
                    );
                  }}
                >
                  <TextField label={c("reason")} name="reason" required maxLength={500} />
                  <Button
                    type="submit"
                    variant={member.status === "active" ? "danger" : "primary"}
                    pending={pending === "status"}
                  >
                    {t(member.status === "active" ? "deactivate" : "reactivate")}
                  </Button>
                </form>
              </>
            )}
          </div>
        )}
      </Dialog>
    </>
  );
}
