"use client";
import type { Schemas } from "@news/api-client/admin";
import { useQueryClient } from "@tanstack/react-query";
import { CalendarDays, Plus } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useLocale, useTranslations } from "next-intl";
import { type FormEvent, useDeferredValue, useState } from "react";
import { STATUS_TONE } from "@/components/editor/panels";
import {
  Badge,
  Button,
  Card,
  Dialog,
  Empty,
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
import { categoryName, flatTree } from "@/lib/categories";
import { contentKeys, useCategories, usePaged, useTime } from "@/lib/queries";

const STATUSES = [
  "draft",
  "submitted",
  "in_review",
  "approved",
  "scheduled",
  "published",
  "unpublished",
  "archived",
] as const;
const TYPES = [
  "article",
  "breaking",
  "video",
  "gallery",
  "live_blog",
  "opinion",
  "short",
  "youtube",
  "live_stream",
  "instagram_import",
] as const;
const CREATE = TYPES.filter((k) => k !== "live_stream" && k !== "instagram_import");
const BULK = ["approve", "publish", "unpublish", "archive"] as const;
const WIDTHS = ["w-5", "w-72", "w-24", "w-24", "w-28", "w-32"];

export default function Content() {
  const t = useTranslations("content");
  const c = useTranslations("common");
  const locale = useLocale();
  const time = useTime();
  const queries = useQueryClient();
  const categories = useCategories();
  const tree = flatTree(categories.data ?? []);
  const [filter, setFilter] = useState({ status: "", type: "", category: "", q: "", mine: false });
  const search = useDeferredValue(filter);
  const [picked, setPicked] = useState<Set<string>>(new Set());
  const [creating, setCreating] = useState(false);
  const [bulk, setBulk] = useState<(typeof BULK)[number] | null>(null);
  const [notice, setNotice] = useState("");
  const list = usePaged([...contentKeys.posts, "list", search], (cursor) =>
    call(() =>
      client.GET("/api/v1/posts", {
        params: {
          query: {
            ...(search.status ? { status: [search.status] } : {}),
            ...(search.type ? { type: search.type } : {}),
            ...(search.category ? { category: search.category } : {}),
            ...(search.q ? { q: search.q } : {}),
            ...(search.mine ? { mine: true } : {}),
            ...(cursor ? { cursor } : {}),
          },
        },
      }),
    ),
  );
  const set = (values: Partial<typeof filter>) => {
    setFilter({ ...filter, ...values });
    setPicked(new Set());
  };
  const control = "tap rounded-sm border border-border-strong bg-surface px-3 text-body-m text-text-primary";
  return (
    <>
      <PageHeader
        title={t("title")}
        lead={t("lead")}
        actions={
          <>
            <Link
              href="/content/calendar"
              className="tap inline-flex items-center gap-2 rounded-sm border border-border-strong bg-surface px-4 text-label hover:bg-surface-sunken"
            >
              <CalendarDays aria-hidden size={18} /> {t("calendar")}
            </Link>
            <Button onClick={() => setCreating(true)}>
              <Plus aria-hidden size={18} /> {t("new")}
            </Button>
          </>
        }
      />
      <div className="mb-4 flex flex-wrap gap-3">
        <input
          type="search"
          aria-label={t("search")}
          placeholder={t("search")}
          value={filter.q}
          onChange={(e) => set({ q: e.target.value })}
          className={`${control} min-w-0 flex-1 basis-48`}
        />
        <select
          aria-label={t("statusLabel")}
          value={filter.status}
          onChange={(e) => set({ status: e.target.value })}
          className={control}
        >
          <option value="">{t("allStatuses")}</option>
          {STATUSES.map((s) => (
            <option key={s} value={s}>
              {t(`status.${s}`)}
            </option>
          ))}
        </select>
        <select
          aria-label={t("type")}
          value={filter.type}
          onChange={(e) => set({ type: e.target.value })}
          className={control}
        >
          <option value="">{t("allTypes")}</option>
          {TYPES.map((k) => (
            <option key={k} value={k}>
              {t(`types.${k}`)}
            </option>
          ))}
        </select>
        <select
          aria-label={t("category")}
          value={filter.category}
          onChange={(e) => set({ category: e.target.value })}
          className={control}
        >
          <option value="">{t("allCategories")}</option>
          {tree.map((x) => (
            <option key={x.id} value={x.id}>
              {"— ".repeat(x.depth - 1)}
              {categoryName(x, locale)}
            </option>
          ))}
        </select>
        <label className="tap flex items-center gap-2 text-label">
          <input
            type="checkbox"
            checked={filter.mine}
            onChange={(e) => set({ mine: e.target.checked })}
            className="size-5"
          />
          {t("mine")}
        </label>
      </div>
      {notice && (
        <div className="mb-4">
          <Notice tone="success">{notice}</Notice>
        </div>
      )}
      {picked.size > 0 && (
        <section
          aria-label={t("bulkActions")}
          className="mb-4 flex flex-wrap items-center gap-2 rounded-md bg-accent-soft p-3"
        >
          <span className="text-label">{t("selected", { n: picked.size })}</span>
          {BULK.map((key) => (
            <Button key={key} variant="secondary" onClick={() => setBulk(key)}>
              {t(`transition.${key}`)}
            </Button>
          ))}
        </section>
      )}
      {list.error ? (
        <ErrorState error={list.error} retry={list.refetch} />
      ) : list.rows?.length === 0 ? (
        <Card>
          <Empty
            title={t("empty")}
            body={t("emptyBody")}
            action={<Button onClick={() => setCreating(true)}>{t("new")}</Button>}
          />
        </Card>
      ) : (
        <Table
          label={t("title")}
          head={["", t("headline"), t("statusLabel"), t("type"), t("category"), t("updated")]}
        >
          {list.rows ? (
            list.rows.map((post) => (
              <Row key={post.id}>
                <Td>
                  <label className="tap flex w-11 items-center">
                    <input
                      type="checkbox"
                      className="size-5"
                      aria-label={t("select", { name: post.headline || t("untitled") })}
                      checked={picked.has(post.id)}
                      onChange={(e) => {
                        const next = new Set(picked);
                        if (e.target.checked) next.add(post.id);
                        else next.delete(post.id);
                        setPicked(next);
                      }}
                    />
                  </label>
                </Td>
                <Td className="md:w-1/2">
                  <Link
                    href={`/content/${post.id}`}
                    prefetch={false}
                    className="tap flex items-center text-text-primary text-title hover:text-accent"
                  >
                    {post.headline || t("untitled")}
                  </Link>
                  <span className="block text-caption text-text-secondary">
                    {post.authors.map((a) => a.display_name).join(", ")}
                    {post.locales.length > 0 && ` · ${post.locales.join(" + ").toUpperCase()}`}
                    {post.editing && ` · ${t("isEditing", { name: post.editing })}`}
                  </span>
                </Td>
                <Td>
                  <span className="tap inline-flex items-center">
                    <Badge tone={STATUS_TONE[post.status]}>{t(`status.${post.status}`)}</Badge>
                  </span>
                </Td>
                <Td>
                  <span className="tap inline-flex items-center">{t(`types.${post.type}`)}</span>
                </Td>
                <Td>
                  <span className="tap inline-flex items-center">
                    {(() => {
                      const found = tree.find((x) => x.id === post.category.id);
                      return found ? categoryName(found, locale) : post.category.name;
                    })()}
                  </span>
                </Td>
                <Td>
                  <span className="tap inline-flex items-center whitespace-nowrap">
                    {time(post.scheduled_at ?? post.updated_at)}
                  </span>
                </Td>
              </Row>
            ))
          ) : (
            <BoneRowsTall />
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
      <NewPost open={creating} onClose={() => setCreating(false)} />
      <BulkDialog
        action={bulk}
        ids={[...picked]}
        onClose={() => setBulk(null)}
        onDone={(text) => {
          setBulk(null);
          setPicked(new Set());
          setNotice(text);
          void queries.invalidateQueries({ queryKey: contentKeys.posts });
        }}
      />
    </>
  );
}

/** Two lines in the second column, so a row keeps its height. */
const BoneRowsTall = () =>
  Array.from({ length: 8 }, (_, r) => (
    // biome-ignore lint/suspicious/noArrayIndexKey: static placeholders
    <Row key={r} data-skeleton="row">
      {WIDTHS.map((w, i) => (
        // biome-ignore lint/suspicious/noArrayIndexKey: static placeholders
        <Td key={i} className={i === 1 ? "md:w-1/2" : undefined}>
          <span className="tap flex items-center">
            <span aria-hidden className={`bone ${w}`}>
              {" "}
            </span>
          </span>
          {i === 1 && (
            <span className="block text-caption">
              <span aria-hidden className="bone w-40">
                {" "}
              </span>
            </span>
          )}
        </Td>
      ))}
    </Row>
  ));

function NewPost({ open, onClose }: { open: boolean; onClose: () => void }) {
  const t = useTranslations("content");
  const locale = useLocale();
  const router = useRouter();
  const categories = useCategories();
  const tree = flatTree(categories.data ?? []).filter((x) => x.can_create && x.visibility !== "archived");
  const [pending, setPending] = useState(false);
  const [problem, setProblem] = useState<unknown>(null);
  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    setPending(true);
    setProblem(null);
    try {
      const post = await call(() =>
        client.POST("/api/v1/posts", {
          body: {
            type: String(form.get("type")) as Schemas["PostTypeEnum"],
            category: String(form.get("category")),
            locale: String(form.get("locale")) as "sw" | "en",
            headline: String(form.get("headline")),
          },
        }),
      );
      router.push(`/content/${post.id}`);
    } catch (err) {
      setProblem(err);
      setPending(false);
    }
  };
  return (
    <Dialog open={open} onClose={onClose} title={t("new")}>
      <form onSubmit={submit} className="flex flex-col gap-4">
        <FormError error={problem} />
        {categories.data && tree.length === 0 && <Notice tone="warning">{t("noCategory")}</Notice>}
        <TextField label={t("headline")} name="headline" maxLength={200} autoFocus />
        <Field label={t("type")}>
          {(p) => (
            <select name="type" {...p}>
              {CREATE.map((k) => (
                <option key={k} value={k}>
                  {t(`types.${k}`)}
                </option>
              ))}
            </select>
          )}
        </Field>
        <Field label={t("category")}>
          {(p) => (
            <select name="category" required {...p}>
              {tree.map((x) => (
                <option key={x.id} value={x.id}>
                  {"— ".repeat(x.depth - 1)}
                  {categoryName(x, locale)}
                </option>
              ))}
            </select>
          )}
        </Field>
        <Field label={t("firstLanguage")}>
          {(p) => (
            <select name="locale" {...p}>
              <option value="sw">{t("language.sw")}</option>
              <option value="en">{t("language.en")}</option>
            </select>
          )}
        </Field>
        <Button type="submit" pending={pending} disabled={tree.length === 0} className="self-start">
          {t("start")}
        </Button>
      </form>
    </Dialog>
  );
}

function BulkDialog({
  action,
  ids,
  onClose,
  onDone,
}: {
  action: (typeof BULK)[number] | null;
  ids: string[];
  onClose: () => void;
  onDone: (text: string) => void;
}) {
  const t = useTranslations("content");
  const e = useTranslations("errors");
  const [pending, setPending] = useState(false);
  const [problem, setProblem] = useState<unknown>(null);
  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!action) return;
    const note = String(new FormData(event.currentTarget).get("note") ?? "");
    setPending(true);
    setProblem(null);
    try {
      const r = await call(() => client.POST("/api/v1/posts/bulk", { body: { key: action, ids, note } }));
      if (r.approval_required) return onDone(t("sentForApproval"));
      const failed = r.results.filter((x) => x.result !== "ok");
      const why = [...new Set(failed.map((x) => x.result))]
        .map((code) => (e.has(code as never) ? e(code as never) : code))
        .join(" ");
      onDone(
        `${t("bulkDone", { n: r.results.length - failed.length })} ${failed.length ? t("bulkFailed", { n: failed.length }) : ""} ${why}`.trim(),
      );
    } catch (err) {
      setProblem(err);
    } finally {
      setPending(false);
    }
  };
  return (
    <Dialog
      open={action !== null}
      onClose={onClose}
      title={action ? t(`transition.${action}`) : ""}
      description={t("selected", { n: ids.length })}
    >
      <form onSubmit={submit} className="flex flex-col gap-4">
        <FormError error={problem} />
        <TextField
          label={t(action === "unpublish" ? "why" : "noteOptional")}
          name="note"
          required={action === "unpublish"}
          maxLength={2000}
        />
        <Button
          type="submit"
          pending={pending}
          variant={action === "archive" || action === "unpublish" ? "danger" : "primary"}
          className="self-start"
        >
          {action ? t(`transition.${action}`) : ""}
        </Button>
      </form>
    </Dialog>
  );
}
