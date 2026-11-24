"use client";
import type { Schemas } from "@news/api-client/admin";
import { useQueryClient } from "@tanstack/react-query";
import { Plus } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { type FormEvent, useState } from "react";
import {
  ActionBone,
  Badge,
  BoneRows,
  Button,
  Dialog,
  ErrorState,
  FormError,
  PageHeader,
  Row,
  Table,
  Td,
  TextField,
} from "@/components/ui";
import { call, client } from "@/lib/api";
import { keys, useCan, useRoles, useSession } from "@/lib/queries";

type Role = Schemas["Role"];
export default function Roles() {
  const t = useTranslations("roles");
  const c = useTranslations("common");
  const en = useLocale() === "en";
  const can = useCan();
  const queries = useQueryClient();
  const { data: session } = useSession();
  const { data, error, refetch } = useRoles();
  const [role, setRole] = useState<Role | "new" | null>(null);
  const [problem, setProblem] = useState<unknown>(null);
  const [pending, setPending] = useState("");
  if (error && !data) return <ErrorState error={error} retry={refetch} />;
  const current = role === "new" ? null : role;
  const locked = current?.key === "super_admin" || !can("roles.manage");

  async function act(name: string, action: () => Promise<unknown>) {
    setPending(name);
    setProblem(null);
    try {
      await action();
      await queries.invalidateQueries({ queryKey: keys.roles });
      setRole(null);
    } catch (e) {
      setProblem(e);
    } finally {
      setPending("");
    }
  }
  function save(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    const text = (n: string) => String(form.get(n) ?? "");
    const body = {
      key: text("key"),
      name_en: text("name_en"),
      name_sw: text("name_sw"),
      description: text("description"),
      permissions: form.getAll("permissions").map(String),
    };
    act("save", () =>
      call<unknown>(() =>
        current
          ? client.PUT("/api/v1/roles/{role_id}", { params: { path: { role_id: current.id } }, body })
          : client.POST("/api/v1/roles", { body }),
      ),
    );
  }
  return (
    <>
      <PageHeader
        title={t("title")}
        lead={t("lead")}
        actions={
          session ? (
            can("roles.manage") && (
              <Button
                onClick={() => {
                  setProblem(null);
                  setRole("new");
                }}
              >
                <Plus aria-hidden size={18} />
                {t("new")}
              </Button>
            )
          ) : (
            <ActionBone />
          )
        }
      />
      <Table label={t("title")} head={[t("name"), t("permissions"), t("members"), ""]}>
        {data ? (
          data.roles.map((r) => (
            <Row key={r.id}>
              <Td>
                <span className="flex flex-wrap items-center gap-2">
                  {en ? r.name_en : r.name_sw}
                  {r.is_system && <Badge>{t("system")}</Badge>}
                  {r.is_privileged && <Badge tone="warning">{t("privileged")}</Badge>}
                </span>
              </Td>
              <Td className="tabular-nums">{r.permissions.length}</Td>
              <Td className="tabular-nums">{r.members}</Td>
              <Td>
                <Button
                  variant="ghost"
                  aria-label={t("openName", { name: en ? r.name_en : r.name_sw })}
                  onClick={() => {
                    setProblem(null);
                    setRole(r);
                  }}
                >
                  {c("open")}
                </Button>
              </Td>
            </Row>
          ))
        ) : (
          <BoneRows action widths={["w-40", "w-8", "w-8", "w-16"]} rows={10} />
        )}
      </Table>
      <Dialog
        open={role !== null}
        onClose={() => setRole(null)}
        title={current ? (en ? current.name_en : current.name_sw) : t("new")}
        description={locked ? t("locked") : undefined}
      >
        <form key={current?.id ?? "new"} onSubmit={save} className="flex flex-col gap-4">
          <FormError error={problem} />
          {!current && (
            <TextField label={t("key")} help={t("keyHelp")} name="key" pattern="[a-z0-9_\-]+" required />
          )}
          <TextField
            label={t("nameSw")}
            name="name_sw"
            defaultValue={current?.name_sw}
            required
            disabled={locked}
          />
          <TextField
            label={t("nameEn")}
            name="name_en"
            defaultValue={current?.name_en}
            required
            disabled={locked}
          />
          <TextField
            label={t("description")}
            name="description"
            defaultValue={current?.description}
            disabled={locked}
          />
          <fieldset disabled={locked} className="flex flex-col">
            <legend className="text-label">{t("permissions")}</legend>
            {data?.permissions.map((p) => (
              <label key={p.code} className="tap flex items-center gap-3 text-label">
                <input
                  type="checkbox"
                  name="permissions"
                  value={p.code}
                  defaultChecked={current?.permissions.includes(p.code)}
                  className="size-5 shrink-0"
                />
                <span className="flex-1">{en ? p.en : p.sw}</span>
                {p.sensitive && <Badge tone="warning">{t("sensitive")}</Badge>}
              </label>
            ))}
          </fieldset>
          {!locked && (
            <Button type="submit" pending={pending === "save"}>
              {c("save")}
            </Button>
          )}
          {!locked && current && !current.is_system && (
            <Button
              variant="danger"
              pending={pending === "delete"}
              onClick={() =>
                act("delete", () =>
                  call(() =>
                    client.DELETE("/api/v1/roles/{role_id}", { params: { path: { role_id: current.id } } }),
                  ),
                )
              }
            >
              {t("delete")}
            </Button>
          )}
        </form>
      </Dialog>
    </>
  );
}
