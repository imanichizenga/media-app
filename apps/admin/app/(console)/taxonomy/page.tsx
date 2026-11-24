"use client";
import type { Schemas } from "@news/api-client/admin";
import { useQueryClient } from "@tanstack/react-query";
import { ArrowDown, ArrowUp, GripVertical, Pencil, Plus } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { type DragEvent, type FormEvent, type ReactNode, useDeferredValue, useState } from "react";
import {
  Badge,
  Bone,
  Button,
  Card,
  cx,
  Dialog,
  Empty,
  ErrorState,
  Field,
  FormError,
  PageHeader,
  Row,
  Table,
  Td,
  TextField,
} from "@/components/ui";
import { call, client } from "@/lib/api";
import { type Category, categoryName, flatTree } from "@/lib/categories";
import { contentKeys, useCan, useCategories, usePaged } from "@/lib/queries";

const TABS = ["categories", "tags", "stories", "redirects"] as const;
export default function Taxonomy() {
  const t = useTranslations("taxonomy");
  const can = useCan();
  const [tab, setTab] = useState<(typeof TABS)[number]>("categories");
  const tabs = TABS.filter((k) => k !== "redirects" || can("taxonomy.manage"));
  return (
    <>
      <PageHeader title={t("title")} lead={t("lead")} />
      <div role="tablist" aria-label={t("title")} className="mb-4 flex gap-2 overflow-x-auto">
        {tabs.map((k) => (
          <button
            key={k}
            type="button"
            role="tab"
            aria-selected={tab === k}
            onClick={() => setTab(k)}
            className={cx(
              "tap shrink-0 rounded-sm px-4 text-label",
              tab === k ? "bg-accent-soft text-accent" : "text-text-secondary hover:bg-surface-sunken",
            )}
          >
            {t(`tab.${k}`)}
          </button>
        ))}
      </div>
      {tab === "categories" && <Categories />}
      {tab === "tags" && <Tags />}
      {tab === "stories" && <Stories />}
      {tab === "redirects" && <Redirects />}
    </>
  );
}

/** Runs one change, shows what went wrong, and refreshes what it touched. */
function useAct(keys: readonly unknown[]) {
  const queries = useQueryClient();
  const [pending, setPending] = useState(false);
  const [problem, setProblem] = useState<unknown>(null);
  const act = async (run: () => Promise<unknown>, done?: () => void) => {
    setPending(true);
    setProblem(null);
    try {
      await run();
      await queries.invalidateQueries({ queryKey: keys });
      done?.();
    } catch (err) {
      setProblem(err);
    } finally {
      setPending(false);
    }
  };
  return { pending, problem, setProblem, act };
}

// ---- categories ----
function Categories() {
  const t = useTranslations("taxonomy");
  const locale = useLocale();
  const can = useCan();
  const { data, error, refetch } = useCategories();
  const rows = flatTree(data ?? []);
  const [edit, setEdit] = useState<{ row: Category | null; parent: string | null } | null>(null);
  const [drag, setDrag] = useState<Category | null>(null);
  const { act, problem } = useAct(contentKeys.categories);
  const siblings = (c: Category) => rows.filter((x) => x.parent === c.parent);
  const move = (c: Category, parent: string | null, position: number) =>
    act(() =>
      call(() =>
        client.POST("/api/v1/categories/{category_id}/move", {
          params: { path: { category_id: c.id } },
          body: { parent, position },
        }),
      ),
    );
  // Dropping on a row places the dragged category before it, at the same level.
  const drop = (target: Category) => (e: DragEvent) => {
    e.preventDefault();
    if (drag && drag.id !== target.id)
      void move(
        drag,
        target.parent,
        siblings(target)
          .filter((x) => x.id !== drag.id)
          .findIndex((x) => x.id === target.id),
      );
    setDrag(null);
  };
  if (error) return <ErrorState error={error} retry={refetch} />;
  const button = "tap grid w-11 place-items-center rounded-sm hover:bg-surface-sunken disabled:opacity-30";
  return (
    <>
      <div className="mb-4 flex items-center gap-4">
        {can("taxonomy.manage") && (
          <Button onClick={() => setEdit({ row: null, parent: null })}>
            <Plus aria-hidden size={18} /> {t("newCategory")}
          </Button>
        )}
      </div>
      <FormError error={problem} />
      <ul className="divide-y divide-border rounded-md border border-border bg-surface">
        {data
          ? rows.map((c) => {
              const around = siblings(c);
              const at = around.findIndex((x) => x.id === c.id);
              const name = categoryName(c, locale);
              return (
                <li
                  key={c.id}
                  onDragOver={(e) => drag && e.preventDefault()}
                  onDrop={drop(c)}
                  className={cx(
                    "flex flex-wrap items-center gap-2 px-3 py-2",
                    drag?.id === c.id && "opacity-50",
                  )}
                  style={{ paddingLeft: 12 + (c.depth - 1) * 28 }}
                >
                  {c.can_manage && (
                    // biome-ignore lint/a11y/noStaticElementInteractions: dragging is extra; the arrow buttons do the same
                    <span
                      draggable
                      onDragStart={() => setDrag(c)}
                      onDragEnd={() => setDrag(null)}
                      title={t("dragHelp")}
                      className="tap hidden w-8 cursor-grab place-items-center text-text-tertiary lg:grid"
                    >
                      <GripVertical aria-hidden size={18} />
                    </span>
                  )}
                  <span
                    aria-hidden
                    className="size-3 shrink-0 rounded-full border border-border"
                    style={{ background: c.color || "transparent" }}
                  />
                  <span className="min-w-0 flex-1 basis-40">
                    <span className="block text-title">{name}</span>
                    <span className="block text-caption text-text-secondary">
                      {[c.texts.sw?.slug, c.texts.en?.slug].filter(Boolean).join(" · ")}
                      {c.editors.length > 0 && ` · ${c.editors.map((x) => x.display_name).join(", ")}`}
                    </span>
                  </span>
                  <span className="text-caption text-text-secondary">{t("posts", { n: c.posts })}</span>
                  {c.visibility !== "public" && <Badge>{t(`visibility.${c.visibility}`)}</Badge>}
                  {c.can_manage && (
                    <span className="flex">
                      <button
                        type="button"
                        className={button}
                        disabled={at === 0}
                        aria-label={t("up", { name })}
                        onClick={() => move(c, c.parent, at - 1)}
                      >
                        <ArrowUp aria-hidden size={18} />
                      </button>
                      <button
                        type="button"
                        className={button}
                        disabled={at === around.length - 1}
                        aria-label={t("down", { name })}
                        onClick={() => move(c, c.parent, at + 1)}
                      >
                        <ArrowDown aria-hidden size={18} />
                      </button>
                      <button
                        type="button"
                        className={button}
                        disabled={c.depth >= 3}
                        aria-label={t("addChild", { name })}
                        onClick={() => setEdit({ row: null, parent: c.id })}
                      >
                        <Plus aria-hidden size={18} />
                      </button>
                      <button
                        type="button"
                        className={button}
                        aria-label={t("editName", { name })}
                        onClick={() => setEdit({ row: c, parent: c.parent })}
                      >
                        <Pencil aria-hidden size={18} />
                      </button>
                    </span>
                  )}
                </li>
              );
            })
          : Array.from({ length: 10 }, (_, i) => (
              // biome-ignore lint/suspicious/noArrayIndexKey: static placeholders
              <li key={i} className="flex items-center gap-2 px-3 py-2" data-skeleton="row">
                <span className="tap hidden w-8 lg:block" />
                <span className="bone size-3 rounded-full!" />
                <span className="min-w-0 flex-1">
                  <span className="block text-title">
                    <Bone className="w-32" />
                  </span>
                  <span className="block text-caption">
                    <Bone className="w-40" />
                  </span>
                </span>
                <span className="tap bone w-44" />
              </li>
            ))}
      </ul>
      <Dialog
        open={edit !== null}
        onClose={() => setEdit(null)}
        title={edit?.row ? categoryName(edit.row, locale) : t("newCategory")}
        wide
      >
        {edit && (
          <CategoryForm
            key={edit.row?.id ?? "new"}
            row={edit.row}
            parent={edit.parent}
            all={rows}
            onDone={() => setEdit(null)}
          />
        )}
      </Dialog>
    </>
  );
}

const ICONS = [
  "newspaper",
  "landmark",
  "trending-up",
  "trophy",
  "heart-pulse",
  "graduation-cap",
  "cpu",
  "music",
  "leaf",
  "globe",
  "earth",
  "message-square-quote",
  "sprout",
  "film",
  "bus",
  "scale",
];
const POLICY = ["likes", "comments", "bookmarks", "shares", "reposts"] as const;
const MODES = ["open", "verified", "premoderated", "closed"] as const;
function CategoryForm({
  row,
  parent,
  all,
  onDone,
}: {
  row: Category | null;
  parent: string | null;
  all: Category[];
  onDone: () => void;
}) {
  const t = useTranslations("taxonomy");
  const g = useTranslations("engagement");
  const c = useTranslations("common");
  const content = useTranslations("content");
  const locale = useLocale();
  const { act, pending, problem } = useAct(contentKeys.categories);
  const [target, setTarget] = useState("");
  const [under, setUnder] = useState(row?.parent ?? "");
  const submit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    const get = (k: string) => String(form.get(k) ?? "").trim();
    const text = (l: "sw" | "en") => ({
      name: get(`${l}.name`),
      slug: get(`${l}.slug`),
      description: get(`${l}.description`),
      seo_title: get(`${l}.seo_title`),
      seo_description: get(`${l}.seo_description`),
    });
    const engagement = Object.fromEntries(
      POLICY.flatMap((k) => {
        const v = get(`policy.${k}`);
        return v ? [[k, k === "comments" ? v : v === "true"]] : [];
      }),
    );
    const body = {
      parent,
      version: row?.version ?? 0,
      icon: get("icon"),
      color: form.get("hasColor") ? get("color") : "",
      visibility: get("visibility") as Schemas["VisibilityEnum"],
      engagement,
      texts: { sw: text("sw"), ...(get("en.name") ? { en: text("en") } : {}) },
    };
    void act(async () => {
      if (row) {
        await call(() =>
          client.PUT("/api/v1/categories/{category_id}", { params: { path: { category_id: row.id } }, body }),
        );
        if (under !== (row.parent ?? ""))
          await call(() =>
            client.POST("/api/v1/categories/{category_id}/move", {
              params: { path: { category_id: row.id } },
              body: { parent: under || null, position: 9999 },
            }),
          );
      } else await call(() => client.POST("/api/v1/categories", { body }));
    }, onDone);
  };
  const inside = (x: Category): boolean => {
    for (let p: Category | undefined = x; p; p = all.find((y) => y.id === p?.parent))
      if (p.id === row?.id) return true;
    return false;
  };
  const language = (l: "sw" | "en"): ReactNode => {
    const v = row?.texts[l];
    return (
      <fieldset className="flex flex-col gap-3 rounded-md border border-border p-4">
        <legend className="px-1 text-title">{content(`language.${l}`)}</legend>
        <TextField
          label={t("name")}
          name={`${l}.name`}
          defaultValue={v?.name}
          required={l === "sw"}
          maxLength={80}
        />
        <TextField
          label={t("slug")}
          name={`${l}.slug`}
          defaultValue={v?.slug}
          maxLength={80}
          pattern="[a-z0-9\-]*"
          help={row ? t("slugMoves") : t("slugHelp")}
        />
        <TextField
          label={t("description")}
          name={`${l}.description`}
          defaultValue={v?.description}
          maxLength={500}
        />
        <TextField
          label={t("seoTitle")}
          name={`${l}.seo_title`}
          defaultValue={v?.seo_title}
          maxLength={120}
        />
        <TextField
          label={t("seoDescription")}
          name={`${l}.seo_description`}
          defaultValue={v?.seo_description}
          maxLength={320}
        />
      </fieldset>
    );
  };
  return (
    <form onSubmit={submit} className="flex flex-col gap-5">
      <FormError error={problem} />
      <div className="grid gap-4 md:grid-cols-2">
        {language("sw")}
        {language("en")}
      </div>
      <div className="grid gap-4 md:grid-cols-3">
        {row && (
          <Field label={t("parent")}>
            {(p) => (
              <select {...p} value={under} onChange={(e) => setUnder(e.target.value)}>
                <option value="">{t("top")}</option>
                {all
                  .filter((x) => x.depth < 3 && !inside(x))
                  .map((x) => (
                    <option key={x.id} value={x.id}>
                      {"— ".repeat(x.depth - 1)}
                      {categoryName(x, locale)}
                    </option>
                  ))}
              </select>
            )}
          </Field>
        )}
        <Field label={t("icon")}>
          {(p) => (
            <select {...p} name="icon" defaultValue={row?.icon ?? ""}>
              <option value="">{t("noIcon")}</option>
              {[...new Set([...ICONS, row?.icon ?? ""])].filter(Boolean).map((i) => (
                <option key={i}>{i}</option>
              ))}
            </select>
          )}
        </Field>
        <Field label={t("visibilityLabel")}>
          {(p) => (
            <select {...p} name="visibility" defaultValue={row?.visibility ?? "public"}>
              {(["public", "hidden", "archived"] as const).map((v) => (
                <option key={v} value={v}>
                  {t(`visibility.${v}`)}
                </option>
              ))}
            </select>
          )}
        </Field>
        <div className="flex items-end gap-3">
          <label className="tap flex items-center gap-2 text-label">
            <input type="checkbox" name="hasColor" defaultChecked={Boolean(row?.color)} className="size-5" />
            {t("color")}
          </label>
          <input
            type="color"
            name="color"
            aria-label={t("color")}
            defaultValue={row?.color || "#0b5cad"}
            className="tap w-16 rounded-sm border border-border-strong bg-surface p-1"
          />
        </div>
      </div>
      <fieldset className="grid gap-4 rounded-md border border-border p-4 md:grid-cols-3">
        <legend className="px-1 text-title">{t("engagement")}</legend>
        {POLICY.map((k) => {
          const now = (row?.engagement as Record<string, unknown> | undefined)?.[k];
          return (
            <Field key={k} label={g(`kind.${k}`)}>
              {(p) => (
                <select {...p} name={`policy.${k}`} defaultValue={now === undefined ? "" : String(now)}>
                  <option value="">{t("inherit")}</option>
                  {k === "comments"
                    ? MODES.map((m) => (
                        <option key={m} value={m}>
                          {g(`mode.${m}`)}
                        </option>
                      ))
                    : ["true", "false"].map((v) => (
                        <option key={v} value={v}>
                          {g(v === "true" ? "on" : "off")}
                        </option>
                      ))}
                </select>
              )}
            </Field>
          );
        })}
      </fieldset>
      <Button type="submit" pending={pending} className="self-start">
        {c("save")}
      </Button>
      {row && (
        <fieldset className="flex flex-wrap items-end gap-3 rounded-md border border-border p-4">
          <legend className="px-1 text-title">{t("merge")}</legend>
          <div className="min-w-48 flex-1">
            <Field label={t("mergeInto")} help={t("mergeHelp")}>
              {(p) => (
                <select {...p} value={target} onChange={(e) => setTarget(e.target.value)}>
                  <option value="">—</option>
                  {all
                    .filter((x) => x.id !== row.id)
                    .map((x) => (
                      <option key={x.id} value={x.id}>
                        {categoryName(x, locale)}
                      </option>
                    ))}
                </select>
              )}
            </Field>
          </div>
          <Button
            variant="danger"
            disabled={!target}
            pending={pending}
            onClick={() =>
              act(
                () =>
                  call(() =>
                    client.POST("/api/v1/categories/{category_id}/merge", {
                      params: { path: { category_id: row.id } },
                      body: { target },
                    }),
                  ),
                onDone,
              )
            }
          >
            {t("merge")}
          </Button>
        </fieldset>
      )}
    </form>
  );
}

// ---- tags ----
const SEARCH =
  "tap w-full max-w-sm rounded-sm border border-border-strong bg-surface px-3 text-body-m text-text-primary";
const BoneList = ({ widths }: { widths: string[] }) =>
  Array.from({ length: 8 }, (_, r) => (
    // biome-ignore lint/suspicious/noArrayIndexKey: static placeholders
    <Row key={r} data-skeleton="row">
      {widths.map((w, i) => (
        // biome-ignore lint/suspicious/noArrayIndexKey: static placeholders
        <Td key={i}>
          <span className="tap flex items-center">
            <Bone className={w} />
          </span>
        </Td>
      ))}
    </Row>
  ));
const Cell = ({ children }: { children: ReactNode }) => (
  <Td>
    <span className="tap flex items-center">{children}</span>
  </Td>
);

function Tags() {
  const t = useTranslations("taxonomy");
  const c = useTranslations("common");
  const can = useCan();
  const [q, setQ] = useState("");
  const search = useDeferredValue(q);
  const [edit, setEdit] = useState<Schemas["Tag"] | "new" | null>(null);
  const list = usePaged(contentKeys.tags(search), (cursor) =>
    call(() =>
      client.GET("/api/v1/tags", { params: { query: { q: search, ...(cursor ? { cursor } : {}) } } }),
    ),
  );
  return (
    <>
      <div className="mb-4 flex flex-wrap gap-3">
        <input
          type="search"
          aria-label={t("searchTags")}
          placeholder={t("searchTags")}
          value={q}
          onChange={(e) => setQ(e.target.value)}
          className={SEARCH}
        />
        {can("taxonomy.manage") && (
          <Button onClick={() => setEdit("new")}>
            <Plus aria-hidden size={18} /> {t("newTag")}
          </Button>
        )}
      </div>
      {list.error ? (
        <ErrorState error={list.error} retry={list.refetch} />
      ) : list.rows?.length === 0 ? (
        <Card>
          <Empty title={t("noTags")} />
        </Card>
      ) : (
        <Table label={t("tab.tags")} head={[t("nameSw"), t("nameEn"), t("synonyms"), t("used"), ""]}>
          {list.rows ? (
            list.rows.map((tag) => (
              <Row key={tag.id}>
                <Cell>{tag.name_sw}</Cell>
                <Cell>{tag.name_en}</Cell>
                <Cell>{tag.synonyms.join(", ") || "—"}</Cell>
                <Cell>{tag.posts}</Cell>
                <Cell>
                  {can("taxonomy.manage") ? (
                    <Button
                      variant="ghost"
                      onClick={() => setEdit(tag)}
                      aria-label={t("editName", { name: tag.name_sw })}
                    >
                      {c("open")}
                    </Button>
                  ) : null}
                </Cell>
              </Row>
            ))
          ) : (
            <BoneList widths={["w-28", "w-28", "w-40", "w-8", "w-16"]} />
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
        open={edit !== null}
        onClose={() => setEdit(null)}
        title={edit === "new" ? t("newTag") : (edit?.name_sw ?? "")}
      >
        {edit && <TagForm tag={edit === "new" ? null : edit} onDone={() => setEdit(null)} />}
      </Dialog>
    </>
  );
}
function TagForm({ tag, onDone }: { tag: Schemas["Tag"] | null; onDone: () => void }) {
  const t = useTranslations("taxonomy");
  const c = useTranslations("common");
  const { act, pending, problem } = useAct(["tags"]);
  const others = usePaged(contentKeys.tags(""), () => call(() => client.GET("/api/v1/tags")), tag !== null);
  const [target, setTarget] = useState("");
  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={(e) => {
        e.preventDefault();
        const form = new FormData(e.currentTarget);
        const get = (k: string) => String(form.get(k) ?? "").trim();
        const body = {
          name_sw: get("name_sw"),
          name_en: get("name_en"),
          slug: get("slug"),
          synonyms: get("synonyms")
            .split(",")
            .map((x) => x.trim())
            .filter(Boolean),
        };
        void act(
          () =>
            call(() =>
              tag
                ? client.PUT("/api/v1/tags/{tag_id}", { params: { path: { tag_id: tag.id } }, body })
                : client.POST("/api/v1/tags", { body }),
            ),
          onDone,
        );
      }}
    >
      <FormError error={problem} />
      <TextField label={t("nameSw")} name="name_sw" required maxLength={80} defaultValue={tag?.name_sw} />
      <TextField label={t("nameEn")} name="name_en" required maxLength={80} defaultValue={tag?.name_en} />
      <TextField
        label={t("slug")}
        name="slug"
        maxLength={80}
        pattern="[a-z0-9\-]*"
        defaultValue={tag?.slug}
        help={tag ? t("slugMoves") : t("slugHelp")}
      />
      <TextField
        label={t("synonyms")}
        name="synonyms"
        defaultValue={tag?.synonyms.join(", ")}
        help={t("synonymsHelp")}
      />
      <Button type="submit" pending={pending} className="self-start">
        {c("save")}
      </Button>
      {tag && (
        <fieldset className="flex flex-wrap items-end gap-3 rounded-md border border-border p-4">
          <legend className="px-1 text-title">{t("merge")}</legend>
          <div className="min-w-40 flex-1">
            <Field label={t("mergeInto")}>
              {(p) => (
                <select {...p} value={target} onChange={(e) => setTarget(e.target.value)}>
                  <option value="">—</option>
                  {others.rows
                    ?.filter((x) => x.id !== tag.id)
                    .map((x) => (
                      <option key={x.id} value={x.id}>
                        {x.name_sw}
                      </option>
                    ))}
                </select>
              )}
            </Field>
          </div>
          <Button
            variant="danger"
            disabled={!target}
            pending={pending}
            onClick={() =>
              act(
                () =>
                  call(() =>
                    client.POST("/api/v1/tags/{tag_id}/merge", {
                      params: { path: { tag_id: tag.id } },
                      body: { target },
                    }),
                  ),
                onDone,
              )
            }
          >
            {t("merge")}
          </Button>
        </fieldset>
      )}
    </form>
  );
}

// ---- stories ----
function Stories() {
  const t = useTranslations("taxonomy");
  const c = useTranslations("common");
  const can = useCan();
  const [edit, setEdit] = useState<Schemas["Story"] | "new" | null>(null);
  const list = usePaged(contentKeys.stories("list"), (cursor) =>
    call(() => client.GET("/api/v1/stories", { params: { query: cursor ? { cursor } : {} } })),
  );
  return (
    <>
      <div className="mb-4 flex">
        {can("taxonomy.manage") && (
          <Button onClick={() => setEdit("new")}>
            <Plus aria-hidden size={18} /> {t("newStory")}
          </Button>
        )}
      </div>
      {list.error ? (
        <ErrorState error={list.error} retry={list.refetch} />
      ) : list.rows?.length === 0 ? (
        <Card>
          <Empty title={t("noStories")} body={t("storiesBody")} />
        </Card>
      ) : (
        <Table label={t("tab.stories")} head={[t("titleSw"), t("titleEn"), t("used"), t("state"), ""]}>
          {list.rows ? (
            list.rows.map((s) => (
              <Row key={s.id}>
                <Cell>{s.title_sw}</Cell>
                <Cell>{s.title_en}</Cell>
                <Cell>{s.posts}</Cell>
                <Cell>
                  <Badge tone={s.is_active ? "success" : "neutral"}>
                    {t(s.is_active ? "ongoing" : "closed")}
                  </Badge>
                </Cell>
                <Cell>
                  {can("taxonomy.manage") ? (
                    <Button
                      variant="ghost"
                      onClick={() => setEdit(s)}
                      aria-label={t("editName", { name: s.title_sw })}
                    >
                      {c("open")}
                    </Button>
                  ) : null}
                </Cell>
              </Row>
            ))
          ) : (
            <BoneList widths={["w-40", "w-40", "w-8", "w-20", "w-16"]} />
          )}
        </Table>
      )}
      <Dialog
        open={edit !== null}
        onClose={() => setEdit(null)}
        title={edit === "new" ? t("newStory") : (edit?.title_sw ?? "")}
      >
        {edit && <StoryForm story={edit === "new" ? null : edit} onDone={() => setEdit(null)} />}
      </Dialog>
    </>
  );
}
function StoryForm({ story, onDone }: { story: Schemas["Story"] | null; onDone: () => void }) {
  const t = useTranslations("taxonomy");
  const c = useTranslations("common");
  const { act, pending, problem } = useAct(["stories"]);
  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={(e) => {
        e.preventDefault();
        const form = new FormData(e.currentTarget);
        const get = (k: string) => String(form.get(k) ?? "").trim();
        const body = {
          title_sw: get("title_sw"),
          title_en: get("title_en"),
          slug: get("slug"),
          summary_sw: get("summary_sw"),
          summary_en: get("summary_en"),
          is_active: form.has("is_active"),
        };
        void act(
          () =>
            call(() =>
              story
                ? client.PUT("/api/v1/stories/{story_id}", { params: { path: { story_id: story.id } }, body })
                : client.POST("/api/v1/stories", { body }),
            ),
          onDone,
        );
      }}
    >
      <FormError error={problem} />
      <TextField
        label={t("titleSw")}
        name="title_sw"
        required
        maxLength={160}
        defaultValue={story?.title_sw}
      />
      <TextField
        label={t("titleEn")}
        name="title_en"
        required
        maxLength={160}
        defaultValue={story?.title_en}
      />
      <TextField
        label={t("slug")}
        name="slug"
        maxLength={120}
        pattern="[a-z0-9\-]*"
        defaultValue={story?.slug}
        help={story ? t("slugMoves") : t("slugHelp")}
      />
      <TextField label={t("summarySw")} name="summary_sw" maxLength={600} defaultValue={story?.summary_sw} />
      <TextField label={t("summaryEn")} name="summary_en" maxLength={600} defaultValue={story?.summary_en} />
      <label className="tap flex items-center gap-3 text-label">
        <input
          type="checkbox"
          name="is_active"
          defaultChecked={story?.is_active ?? true}
          className="size-5"
        />
        {t("ongoing")}
      </label>
      <Button type="submit" pending={pending} className="self-start">
        {c("save")}
      </Button>
    </form>
  );
}

// ---- redirects ----
function Redirects() {
  const t = useTranslations("taxonomy");
  const c = useTranslations("common");
  const [q, setQ] = useState("");
  const search = useDeferredValue(q);
  const [creating, setCreating] = useState(false);
  const { act, pending, problem, setProblem } = useAct(["redirects"]);
  const list = usePaged(contentKeys.redirects(search), (cursor) =>
    call(() =>
      client.GET("/api/v1/redirects", { params: { query: { q: search, ...(cursor ? { cursor } : {}) } } }),
    ),
  );
  return (
    <>
      <div className="mb-4 flex flex-wrap gap-3">
        <input
          type="search"
          aria-label={t("searchRedirects")}
          placeholder={t("searchRedirects")}
          value={q}
          onChange={(e) => setQ(e.target.value)}
          className={SEARCH}
        />
        <Button
          onClick={() => {
            setProblem(null);
            setCreating(true);
          }}
        >
          <Plus aria-hidden size={18} /> {t("newRedirect")}
        </Button>
      </div>
      {!creating && <FormError error={problem} />}
      {list.error ? (
        <ErrorState error={list.error} retry={list.refetch} />
      ) : list.rows?.length === 0 ? (
        <Card>
          <Empty title={t("noRedirects")} body={t("redirectsBody")} />
        </Card>
      ) : (
        <Table label={t("tab.redirects")} head={[t("from"), t("to"), t("made"), ""]}>
          {list.rows ? (
            list.rows.map((r) => (
              <Row key={r.id}>
                <Cell>{r.from_path}</Cell>
                <Cell>{r.to_path}</Cell>
                <Cell>{t(r.is_automatic ? "automatic" : "byHand")}</Cell>
                <Cell>
                  <Button
                    variant="ghost"
                    pending={pending}
                    aria-label={t("deleteName", { name: r.from_path })}
                    onClick={() =>
                      act(() =>
                        call(() =>
                          client.DELETE("/api/v1/redirects/{redirect_id}", {
                            params: { path: { redirect_id: r.id } },
                          }),
                        ),
                      )
                    }
                  >
                    {t("delete")}
                  </Button>
                </Cell>
              </Row>
            ))
          ) : (
            <BoneList widths={["w-48", "w-48", "w-20", "w-16"]} />
          )}
        </Table>
      )}
      <Dialog open={creating} onClose={() => setCreating(false)} title={t("newRedirect")}>
        <form
          className="flex flex-col gap-4"
          onSubmit={(e) => {
            e.preventDefault();
            const form = new FormData(e.currentTarget);
            const body = {
              from_path: String(form.get("from")).trim(),
              to_path: String(form.get("to")).trim(),
            };
            void act(
              () => call(() => client.POST("/api/v1/redirects", { body })),
              () => setCreating(false),
            );
          }}
        >
          <FormError error={problem} />
          <TextField label={t("from")} name="from" required maxLength={400} placeholder="/zamani" />
          <TextField label={t("to")} name="to" required maxLength={400} placeholder="/habari/mpya" />
          <Button type="submit" pending={pending} className="self-start">
            {c("save")}
          </Button>
        </form>
      </Dialog>
    </>
  );
}
