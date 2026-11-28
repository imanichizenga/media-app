"use client";
import type { Schemas } from "@news/api-client/admin";
import { clock, seconds } from "@news/ui/news";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Check, CircleAlert, CircleCheck, TriangleAlert, X } from "lucide-react";
import { useTimeZone, useTranslations } from "next-intl";
import { type FormEvent, useState } from "react";
import { MediaPicker, Thumb } from "@/components/media/library";
import { Badge, Bone, Button, cx, Dialog, Field, FormError, Notice, TextField } from "@/components/ui";
import { call, client } from "@/lib/api";
import { categoryName, flatTree } from "@/lib/categories";
import type { Data, Draft, Locale, Post, Snapshot, Text } from "@/lib/editor/draft";
import { contentKeys, useAsset, useAuthors, useCategories, useRegions, useTime } from "@/lib/queries";
import { checks } from "@/lib/seo";
import { fromZoned, toZoned } from "@/lib/time";
import { importYouTube } from "./blocks";

type Props = { draft: Draft; snap: Snapshot; locale: Locale; disabled: boolean };
export const STATUS_TONE = {
  draft: "neutral",
  submitted: "accent",
  in_review: "accent",
  approved: "success",
  scheduled: "warning",
  published: "success",
  unpublished: "neutral",
  archived: "neutral",
} as const;
/** datetime-local has no time zone of its own: it is always the newsroom's. */
function useZone() {
  const zone = useTimeZone() ?? "UTC";
  return {
    toLocal: (iso: string | null | undefined) => toZoned(iso, zone),
    fromLocal: (value: string) => fromZoned(value, zone),
  };
}

const Row = ({
  label,
  checked,
  disabled,
  onChange,
}: {
  label: string;
  checked: boolean;
  disabled: boolean;
  onChange: (on: boolean) => void;
}) => (
  <label className="tap flex items-center gap-3 text-label">
    <input
      type="checkbox"
      checked={checked}
      disabled={disabled}
      onChange={(e) => onChange(e.target.checked)}
      className="size-5"
    />
    {label}
  </label>
);

// ---- publish ----
const MAIN = ["publish", "republish", "approve", "submit", "start_review", "schedule"];
export function PublishPanel({ draft, snap, disabled, onDone }: Props & { onDone: (post: Post) => void }) {
  const t = useTranslations("content");
  const time = useTime();
  const { toLocal, fromLocal } = useZone();
  const { post, data } = snap;
  const [ask, setAsk] = useState<Schemas["PostTransition"] | null>(null);
  const [pending, setPending] = useState("");
  const [problem, setProblem] = useState<unknown>(null);
  const now = Date.now();
  const breaking = data.breaking_until ? new Date(data.breaking_until).getTime() > now : false;

  async function run(key: Schemas["TransitionEnum"], note = "", scheduled_at: string | null = null) {
    setPending(key);
    setProblem(null);
    try {
      // Nothing may be decided about words the server has not seen.
      if (!(await draft.flush(false))) throw draft.get().error ?? new Error("unsaved");
      const done = await call(() =>
        client.POST("/api/v1/posts/{post_id}/transition", {
          params: { path: { post_id: post.id } },
          body: { key, version: draft.get().post.version, note, scheduled_at },
        }),
      );
      setAsk(null);
      draft.accept(done);
      onDone(done);
    } catch (err) {
      setProblem(err);
    } finally {
      setPending("");
    }
  }
  const start = (step: Schemas["PostTransition"]) => {
    setProblem(null);
    if (step.note_required || step.key === "schedule") setAsk(step);
    else void run(step.key);
  };
  // A missing credit may be added in another tab, and a file becomes ready on its own.
  const waiting = post.problems.includes("media");
  useQuery({
    queryKey: [...contentKeys.post(post.id), "problems", post.version],
    queryFn: async () => {
      const fresh = await call(() =>
        client.GET("/api/v1/posts/{post_id}", { params: { path: { post_id: post.id } } }),
      );
      draft.refresh(fresh);
      return fresh.problems;
    },
    enabled: post.problems.length > 0,
    refetchInterval: waiting ? 3_000 : false,
    refetchOnWindowFocus: "always",
  });
  const main = MAIN.map((k) => post.transitions.find((s) => s.key === k)).find(Boolean);
  const blocked = post.problems.length > 0;
  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap items-center gap-2">
        <Badge tone={STATUS_TONE[post.status]}>{t(`status.${post.status}`)}</Badge>
        {post.unpublished_changes && <Badge tone="warning">{t("unpublishedChanges")}</Badge>}
        {post.scheduled_at && <span className="text-caption">{time(post.scheduled_at)}</span>}
        {post.status === "published" && (
          <span className="text-caption text-text-secondary">{time(post.published_at)}</span>
        )}
      </div>
      {post.problems.length > 0 && (
        <Notice tone="warning">
          <p>{t("notReady")}</p>
          <ul className="list-disc pl-5">
            {post.problems.map((p) => (
              <li key={p}>{t(`problem.${p}` as never)}</li>
            ))}
          </ul>
        </Notice>
      )}
      {!ask && <FormError error={problem} />}
      <div className="flex flex-col gap-2">
        {post.transitions.map((step) => {
          const needsReady = ["publish", "republish", "schedule"].includes(step.key);
          return (
            <Button
              key={step.key}
              variant={step === main ? "primary" : step.key === "archive" ? "ghost" : "secondary"}
              pending={pending === step.key}
              disabled={Boolean(pending) || (needsReady && blocked)}
              onClick={() => start(step)}
            >
              {t(`transition.${step.key}`)}
            </Button>
          );
        })}
      </div>
      {Object.entries(post.paths).length > 0 && (
        <ul className="text-caption text-text-secondary">
          {Object.entries(post.paths).map(([locale, path]) => (
            <li key={locale} className="break-all">
              {locale.toUpperCase()}: {path}
            </li>
          ))}
        </ul>
      )}
      <Field label={t("embargo")} help={t("embargoHelp")}>
        {(p) => (
          <input
            {...p}
            type="datetime-local"
            disabled={disabled}
            value={toLocal(data.embargo_until)}
            onChange={(e) => draft.change({ embargo_until: fromLocal(e.target.value) })}
          />
        )}
      </Field>
      <Row
        label={t("breaking")}
        checked={breaking}
        disabled={disabled}
        onChange={(on) =>
          draft.change({ breaking_until: on ? new Date(now + 2 * 3_600_000).toISOString() : null })
        }
      />
      {breaking && (
        <Field label={t("breakingUntil")}>
          {(p) => (
            <input
              {...p}
              type="datetime-local"
              disabled={disabled}
              value={toLocal(data.breaking_until)}
              onChange={(e) => draft.change({ breaking_until: fromLocal(e.target.value) })}
            />
          )}
        </Field>
      )}
      {data.type === "live_blog" && (
        <Row
          label={t("liveEnded")}
          checked={Boolean(data.live_ended_at)}
          disabled={disabled}
          onChange={(on) => draft.change({ live_ended_at: on ? new Date().toISOString() : null })}
        />
      )}
      <Notes post={post} />
      <Dialog open={ask !== null} onClose={() => setAsk(null)} title={ask ? t(`transition.${ask.key}`) : ""}>
        <form
          className="flex flex-col gap-4"
          onSubmit={(e: FormEvent<HTMLFormElement>) => {
            e.preventDefault();
            const form = new FormData(e.currentTarget);
            if (ask)
              void run(ask.key, String(form.get("note") ?? ""), fromLocal(String(form.get("at") ?? "")));
          }}
        >
          <FormError error={problem} />
          {ask?.key === "schedule" && (
            <TextField
              label={t("publishAt")}
              name="at"
              type="datetime-local"
              required
              min={toLocal(new Date().toISOString())}
            />
          )}
          <TextField
            label={t(ask?.note_required ? "why" : "noteOptional")}
            name="note"
            required={ask?.note_required}
            minLength={ask?.note_required ? 3 : undefined}
            maxLength={2000}
          />
          <Button type="submit" pending={Boolean(pending)} className="self-start">
            {ask ? t(`transition.${ask.key}`) : ""}
          </Button>
        </form>
      </Dialog>
    </div>
  );
}

function Notes({ post }: { post: Post }) {
  const t = useTranslations("content");
  const c = useTranslations("common");
  const time = useTime();
  const queries = useQueryClient();
  const key = [...contentKeys.post(post.id), "notes"];
  const params = { params: { path: { post_id: post.id } } };
  const notes = useQuery({
    queryKey: [...key, post.version],
    queryFn: () => call(() => client.GET("/api/v1/posts/{post_id}/notes", params)),
  });
  const [text, setText] = useState("");
  const [problem, setProblem] = useState<unknown>(null);
  const send = async (e: FormEvent) => {
    e.preventDefault();
    setProblem(null);
    try {
      await call(() => client.POST("/api/v1/posts/{post_id}/notes", { ...params, body: { text } }));
      setText("");
      await queries.invalidateQueries({ queryKey: key });
    } catch (err) {
      setProblem(err);
    }
  };
  return (
    <section className="flex flex-col gap-3 border-border border-t pt-4">
      <h3 className="text-title">{t("notes")}</h3>
      <ul className="flex flex-col gap-3">
        {notes.data?.results.map((note) => (
          <li key={note.id}>
            <p className="text-caption text-text-secondary">
              {note.author.display_name} · {time(note.created_at)}
              {note.transition && ` · ${t(`transition.${note.transition}` as never)}`}
            </p>
            <p className="whitespace-pre-line">{note.text}</p>
          </li>
        ))}
      </ul>
      <form onSubmit={send} className="flex flex-col gap-2">
        <FormError error={problem} />
        <Field label={t("addNote")} help={t("notesHelp")}>
          {(p) => (
            <textarea
              {...p}
              rows={2}
              maxLength={2000}
              value={text}
              onChange={(e) => setText(e.target.value)}
            />
          )}
        </Field>
        <Button type="submit" variant="secondary" disabled={!text.trim()} className="self-start">
          {c("add")}
        </Button>
      </form>
    </section>
  );
}

// ---- details ----
function Picker({
  kind,
  id,
  disabled,
  label,
  onChange,
}: {
  kind: "image" | "video";
  id: string | null | undefined;
  disabled: boolean;
  label: string;
  onChange: (id: string | null) => void;
}) {
  const t = useTranslations("editor");
  const { data } = useAsset(id ?? null);
  const [open, setOpen] = useState(false);
  return (
    <div className="flex flex-col gap-2">
      <span className="text-label">{label}</span>
      {id &&
        (data ? (
          <Thumb asset={data.asset} className="aspect-video w-full" />
        ) : (
          <span className="bone block! aspect-video w-full" />
        ))}
      {!disabled && (
        <div className="flex gap-2">
          <Button variant="secondary" onClick={() => setOpen(true)}>
            {t(id ? "change" : `choose.${kind}`)}
          </Button>
          {id && (
            <Button variant="ghost" onClick={() => onChange(null)}>
              {t("removeIt")}
            </Button>
          )}
        </div>
      )}
      <MediaPicker kind={kind} open={open} onClose={() => setOpen(false)} onPick={(a) => onChange(a.id)} />
    </div>
  );
}

const Chip = ({
  label,
  onRemove,
  removeLabel,
}: {
  label: string;
  onRemove?: () => void;
  removeLabel: string;
}) => (
  <span className="inline-flex items-center rounded-sm bg-surface-sunken pl-3 text-label">
    {label}
    {onRemove ? (
      <button
        type="button"
        onClick={onRemove}
        aria-label={removeLabel}
        className="tap grid w-11 place-items-center"
      >
        <X aria-hidden size={16} />
      </button>
    ) : (
      <span className="w-3" />
    )}
  </span>
);

function Tags({ draft, snap, disabled }: Omit<Props, "locale">) {
  const t = useTranslations("content");
  const [q, setQ] = useState("");
  const [names, setNames] = useState<Record<string, string>>(() =>
    Object.fromEntries(snap.post.tags.map((x) => [x.id, x.name])),
  );
  const found = useQuery({
    queryKey: contentKeys.tags(q),
    queryFn: () => call(() => client.GET("/api/v1/tags", { params: { query: { q } } })),
    enabled: q.trim().length > 0,
  });
  const ids = snap.data.tags ?? [];
  return (
    <div className="flex flex-col gap-2">
      <TextField
        label={t("tags")}
        type="search"
        value={q}
        disabled={disabled}
        onChange={(e) => setQ(e.target.value)}
      />
      {q && (
        <ul className="max-h-48 overflow-y-auto rounded-sm border border-border">
          {found.data?.results
            .filter((x) => !ids.includes(x.id))
            .map((x) => (
              <li key={x.id}>
                <button
                  type="button"
                  className="tap w-full px-3 text-left hover:bg-surface-sunken"
                  onClick={() => {
                    setNames({ ...names, [x.id]: x.name_sw });
                    draft.change({ tags: [...ids, x.id] });
                    setQ("");
                  }}
                >
                  {x.name_sw} <span className="text-text-secondary">· {x.name_en}</span>
                </button>
              </li>
            ))}
          {found.data?.results.length === 0 && <li className="p-3 text-text-secondary">{t("noTag")}</li>}
        </ul>
      )}
      <div className="flex flex-wrap gap-2">
        {ids.map((id) => (
          <Chip
            key={id}
            label={names[id] ?? "…"}
            removeLabel={t("removeName", { name: names[id] ?? "" })}
            onRemove={disabled ? undefined : () => draft.change({ tags: ids.filter((x) => x !== id) })}
          />
        ))}
      </div>
    </div>
  );
}

function Authors({ draft, snap, disabled }: Omit<Props, "locale">) {
  const t = useTranslations("content");
  const people = useAuthors();
  const ids = snap.data.authors ?? [];
  const locked = disabled || !snap.post.can_change_authors;
  const name = (id: string) =>
    snap.post.people.find((p) => p.id === id)?.display_name ??
    people.data?.find((p) => p.id === id)?.display_name ??
    "…";
  return (
    <div className="flex flex-col gap-2">
      <Field label={t("authors")} help={locked && !disabled ? t("authorsLocked") : undefined}>
        {(p) => (
          <select
            {...p}
            value=""
            disabled={locked}
            onChange={(e) => e.target.value && draft.change({ authors: [...ids, e.target.value] })}
          >
            <option value="">{t("addAuthor")}</option>
            {people.data
              ?.filter((x) => !ids.includes(x.id))
              .map((x) => (
                <option key={x.id} value={x.id}>
                  {x.display_name}
                </option>
              ))}
          </select>
        )}
      </Field>
      <div className="flex flex-wrap gap-2">
        {ids.map((id) => (
          <Chip
            key={id}
            label={name(id)}
            removeLabel={t("removeName", { name: name(id) })}
            onRemove={
              locked || ids.length < 2
                ? undefined
                : () => draft.change({ authors: ids.filter((x) => x !== id) })
            }
          />
        ))}
      </div>
    </div>
  );
}

const TYPES = [
  "article",
  "breaking",
  "video",
  "gallery",
  "live_blog",
  "opinion",
  "short",
  "youtube",
] as const;
export function DetailsPanel({ draft, snap, locale, disabled }: Props) {
  const t = useTranslations("content");
  const e = useTranslations("editor");
  const { data } = snap;
  const categories = useCategories();
  const regions = useRegions();
  const stories = useQuery({
    queryKey: contentKeys.stories(""),
    queryFn: () => call(() => client.GET("/api/v1/stories")),
    staleTime: 60_000,
  });
  const [youtube, setYoutube] = useState("");
  const [problem, setProblem] = useState<unknown>(null);
  const tree = flatTree(categories.data ?? []).filter((c) => c.visibility !== "archived");
  const toggle = (list: string[] | undefined, id: string) =>
    list?.includes(id) ? list.filter((x) => x !== id) : [...(list ?? []), id];
  return (
    <div className="flex flex-col gap-5">
      <Picker
        kind="image"
        label={t("hero")}
        id={data.hero}
        disabled={disabled}
        onChange={(hero) => draft.change({ hero })}
      />
      {["video", "short", "live_blog", "live_stream"].includes(data.type ?? "") && (
        <Picker
          kind="video"
          label={t("mainVideo")}
          id={data.video}
          disabled={disabled}
          onChange={(video) => draft.change({ video })}
        />
      )}
      {data.type === "youtube" && (
        <div className="flex flex-col gap-2">
          <FormError error={problem} />
          <TextField
            label={e("youtubeUrl")}
            help={data.youtube_id ? `youtu.be/${data.youtube_id}` : e("youtubeHelp")}
            value={youtube}
            disabled={disabled}
            onChange={(x) => setYoutube(x.target.value)}
          />
          <Button
            variant="secondary"
            className="self-start"
            disabled={disabled || !youtube}
            onClick={async () => {
              setProblem(null);
              try {
                const v = await importYouTube(youtube);
                draft.change({
                  youtube_id: v.video_id,
                  ...(v.thumbnail && !data.hero ? { hero: v.thumbnail.id } : {}),
                });
                if (!data.texts?.[locale]?.headline)
                  draft.changeText(locale, { headline: v.title.slice(0, 200) });
                setYoutube("");
              } catch (err) {
                setProblem(err);
              }
            }}
          >
            {e("youtubeRead")}
          </Button>
          <TextField
            key={data.youtube_seconds}
            label={e("youtubeLength")}
            help={e("youtubeLengthHelp")}
            inputMode="numeric"
            defaultValue={data.youtube_seconds ? clock(data.youtube_seconds * 1000) : ""}
            disabled={disabled}
            onBlur={(x) => draft.change({ youtube_seconds: seconds(x.target.value) })}
          />
        </div>
      )}
      <Field label={t("type")}>
        {(p) => (
          <select
            {...p}
            value={data.type}
            disabled={disabled}
            onChange={(x) => draft.change({ type: x.target.value as Data["type"] })}
          >
            {[...new Set([...TYPES, data.type ?? "article"])].map((k) => (
              <option key={k} value={k}>
                {t(`types.${k}`)}
              </option>
            ))}
          </select>
        )}
      </Field>
      <Field label={t("category")}>
        {(p) => (
          <select
            {...p}
            value={data.category}
            disabled={disabled}
            onChange={(x) => draft.change({ category: x.target.value })}
          >
            {tree.map((c) => (
              <option key={c.id} value={c.id} disabled={!c.can_create && c.id !== data.category}>
                {"— ".repeat(c.depth - 1)}
                {categoryName(c, locale)}
              </option>
            ))}
          </select>
        )}
      </Field>
      <details>
        <summary className="tap flex cursor-pointer items-center text-label">
          {t("alsoIn", { n: data.secondary_categories?.length ?? 0 })}
        </summary>
        {tree
          .filter((c) => c.id !== data.category)
          .map((c) => (
            <Row
              key={c.id}
              label={`${"— ".repeat(c.depth - 1)}${categoryName(c, locale)}`}
              checked={data.secondary_categories?.includes(c.id) ?? false}
              disabled={
                disabled ||
                ((data.secondary_categories?.length ?? 0) >= 6 && !data.secondary_categories?.includes(c.id))
              }
              onChange={() => draft.change({ secondary_categories: toggle(data.secondary_categories, c.id) })}
            />
          ))}
      </details>
      <Tags draft={draft} snap={snap} disabled={disabled} />
      <Field label={t("story")}>
        {(p) => (
          <select
            {...p}
            value={data.story ?? ""}
            disabled={disabled}
            onChange={(x) => draft.change({ story: x.target.value || null })}
          >
            <option value="">{t("noStory")}</option>
            {stories.data?.results.map((s) => (
              <option key={s.id} value={s.id}>
                {locale === "en" ? s.title_en : s.title_sw}
              </option>
            ))}
          </select>
        )}
      </Field>
      <details>
        <summary className="tap flex cursor-pointer items-center text-label">
          {t("regions", { n: data.regions?.length ?? 0 })}
        </summary>
        {regions.data?.map((r) => (
          <Row
            key={r.id}
            label={locale === "en" ? r.name_en : r.name_sw}
            checked={data.regions?.includes(r.id) ?? false}
            disabled={disabled}
            onChange={() => draft.change({ regions: toggle(data.regions, r.id) })}
          />
        ))}
      </details>
      <Authors draft={draft} snap={snap} disabled={disabled} />
      <Row
        label={t("evergreen")}
        checked={data.is_evergreen ?? false}
        disabled={disabled}
        onChange={(is_evergreen) => draft.change({ is_evergreen })}
      />
      <Row
        label={t("subscribers")}
        checked={data.requires_subscription ?? false}
        disabled={disabled}
        onChange={(requires_subscription) => draft.change({ requires_subscription })}
      />
      <Row
        label={t("sensitive")}
        checked={data.is_sensitive ?? false}
        disabled={disabled}
        onChange={(is_sensitive) => draft.change({ is_sensitive })}
      />
      {data.is_sensitive && (
        <TextField
          label={t("warning")}
          value={data.content_warning ?? ""}
          maxLength={200}
          disabled={disabled}
          onChange={(x) => draft.change({ content_warning: x.target.value })}
        />
      )}
      {["live_blog", "live_stream"].includes(data.type ?? "") && (
        <TextField
          label={t("railTitle")}
          help={t("railTitleHelp")}
          value={data.texts?.[locale]?.rail_title ?? ""}
          maxLength={24}
          disabled={disabled}
          onChange={(x) => draft.changeText(locale, { rail_title: x.target.value })}
        />
      )}
      <TextField
        label={t("updateNote")}
        help={t("updateNoteHelp")}
        value={data.texts?.[locale]?.update_note ?? ""}
        maxLength={400}
        disabled={disabled}
        onChange={(x) => draft.changeText(locale, { update_note: x.target.value })}
      />
      <TextField
        label={t("correctionNote")}
        help={t("correctionNoteHelp")}
        value={data.texts?.[locale]?.correction_note ?? ""}
        maxLength={600}
        disabled={disabled}
        onChange={(x) => draft.changeText(locale, { correction_note: x.target.value })}
      />
      <TextField
        label={t("sourceUrl")}
        type="url"
        value={data.source_url ?? ""}
        maxLength={500}
        disabled={disabled}
        onChange={(x) => draft.change({ source_url: x.target.value.trim() })}
      />
    </div>
  );
}

// ---- SEO ----
const ICON = { good: CircleCheck, warn: TriangleAlert, bad: CircleAlert };
const TONE = { good: "text-success", warn: "text-warning", bad: "text-danger" };
export function SeoPanel({ draft, snap, locale, disabled }: Props) {
  const t = useTranslations("seo");
  const { data, post } = snap;
  const text = data.texts?.[locale] ?? {};
  const hero = useAsset(data.hero ?? null);
  const title = text.seo_title || text.headline || "";
  const description = text.seo_description || text.standfirst || "";
  const path = post.paths[locale] ?? `/…/${text.slug || "…"}`;
  const results = checks({
    headline: text.headline ?? "",
    standfirst: text.standfirst ?? "",
    slug: text.slug ?? "",
    seo_title: text.seo_title ?? "",
    seo_description: text.seo_description ?? "",
    focus_keyword: text.focus_keyword ?? "",
    body: (text.body as never) ?? { version: 1, blocks: [] },
    hasHero: Boolean(data.hero),
    heroAlt: (locale === "en" ? hero.data?.asset.alt_en : hero.data?.asset.alt_sw) ?? "",
  });
  const set = (values: Partial<Text>) => draft.changeText(locale, values);
  return (
    <div className="flex flex-col gap-5">
      <section aria-label={t("google")} className="rounded-md border border-border bg-bg p-4">
        <p className="text-caption text-text-secondary">{t("google")}</p>
        <p className="truncate text-brand-text text-title">{title || "…"}</p>
        <p className="truncate text-caption text-success">{path}</p>
        <p className="line-clamp-2 text-caption text-text-secondary">{description || "…"}</p>
      </section>
      <section aria-label={t("social")} className="overflow-hidden rounded-md border border-border bg-bg">
        {hero.data?.asset.large_url ? (
          <img
            src={hero.data.asset.large_url}
            alt=""
            className="aspect-[1.91/1] w-full object-cover"
            style={{ objectPosition: `${hero.data.asset.focal_x / 10}% ${hero.data.asset.focal_y / 10}%` }}
          />
        ) : (
          <span className="block aspect-[1.91/1] bg-surface-sunken" />
        )}
        <div className="p-3">
          <p className="text-caption text-text-secondary">{t("social")}</p>
          <p className="line-clamp-2 text-title">{title || "…"}</p>
        </div>
      </section>
      <TextField
        label={t("title")}
        help={t("chars", { n: title.length, max: 65 })}
        value={text.seo_title ?? ""}
        placeholder={text.headline}
        maxLength={120}
        disabled={disabled}
        onChange={(e) => set({ seo_title: e.target.value })}
      />
      <Field label={t("description")} help={t("chars", { n: description.length, max: 160 })}>
        {(p) => (
          <textarea
            {...p}
            rows={3}
            maxLength={320}
            disabled={disabled}
            placeholder={text.standfirst}
            value={text.seo_description ?? ""}
            onChange={(e) => set({ seo_description: e.target.value })}
          />
        )}
      </Field>
      <TextField
        label={t("keyword")}
        value={text.focus_keyword ?? ""}
        maxLength={80}
        disabled={disabled}
        onChange={(e) => set({ focus_keyword: e.target.value })}
      />
      <TextField
        label={t("slug")}
        help={post.paths[locale] ? t("slugMoves") : t("slugHelp")}
        value={text.slug ?? ""}
        maxLength={100}
        disabled={disabled}
        onChange={(e) => set({ slug: e.target.value })}
      />
      <ul className="flex flex-col gap-2">
        {results.map((check) => {
          const Icon = ICON[check.state];
          return (
            <li key={check.key} className="flex gap-2">
              <Icon aria-hidden size={18} className={cx("mt-1 shrink-0", TONE[check.state])} />
              <span>
                {t(
                  `check.${check.key}.${check.state === "good" ? "good" : "bad"}` as never,
                  check.values as never,
                )}
              </span>
            </li>
          );
        })}
      </ul>
    </div>
  );
}

// ---- engagement ----
const KINDS = ["likes", "comments", "bookmarks", "shares", "reposts", "live_chat"] as const;
const MODES = ["open", "verified", "premoderated", "closed"] as const;
export function EngagementPanel({ draft, snap, disabled }: Omit<Props, "locale">) {
  const t = useTranslations("engagement");
  const mine = (snap.data.engagement ?? {}) as Record<string, unknown>;
  const inherited = snap.post.inherited_policy as Record<string, unknown>;
  const set = (key: string, value: unknown) => {
    const next = { ...mine, [key]: value };
    if (value === null) delete next[key];
    draft.change({ engagement: next as Data["engagement"] });
  };
  return (
    <div className="flex flex-col gap-4">
      <p className="text-text-secondary">{t("lead")}</p>
      {KINDS.filter((k) => k !== "live_chat" || snap.data.type?.startsWith("live")).map((key) => {
        const base = String(inherited[key]);
        const say = (v: string) =>
          key === "comments" ? t(`mode.${v}` as never) : t(v === "true" ? "on" : "off");
        return (
          <Field key={key} label={t(`kind.${key}`)}>
            {(p) => (
              <select
                {...p}
                disabled={disabled}
                value={mine[key] === undefined || mine[key] === null ? "" : String(mine[key])}
                onChange={(e) => {
                  const v = e.target.value;
                  set(key, v === "" ? null : key === "comments" ? v : v === "true");
                }}
              >
                <option value="">{t("inherit", { value: say(base) })}</option>
                {(key === "comments" ? MODES : ["true", "false"]).map((v) => (
                  <option key={v} value={v}>
                    {say(v)}
                  </option>
                ))}
              </select>
            )}
          </Field>
        );
      })}
    </div>
  );
}

// ---- history ----
export function HistoryPanel({
  snap,
  draft,
  disabled,
  onRestored,
}: Omit<Props, "locale"> & { onRestored: () => void }) {
  const t = useTranslations("content");
  const time = useTime();
  const [open, setOpen] = useState<number | null>(null);
  const list = useQuery({
    queryKey: [...contentKeys.post(snap.post.id), "revisions", snap.post.version],
    queryFn: () =>
      call(() =>
        client.GET("/api/v1/posts/{post_id}/revisions", { params: { path: { post_id: snap.post.id } } }),
      ),
  });
  return (
    <>
      <ul className="flex flex-col">
        {(list.data?.results ?? Array.from({ length: 4 }, () => null)).map((r, i) =>
          r ? (
            <li key={r.number}>
              <button
                type="button"
                className="tap w-full rounded-sm px-2 py-2 text-left hover:bg-surface-sunken"
                onClick={() => setOpen(r.number)}
              >
                <span className="block text-label">
                  {t(`revision.${r.kind}`)} · r{r.number}
                </span>
                <span className="block text-caption text-text-secondary">
                  {r.author.display_name} · {time(r.updated_at)}
                </span>
              </button>
            </li>
          ) : (
            // biome-ignore lint/suspicious/noArrayIndexKey: static placeholders
            <li key={i} className="px-2 py-2">
              <span className="block text-label">
                <Bone className="w-32" />
              </span>
              <span className="block text-caption">
                <Bone className="w-40" />
              </span>
            </li>
          ),
        )}
      </ul>
      <Dialog
        open={open !== null}
        onClose={() => setOpen(null)}
        title={t("changesIn", { n: open ?? 0 })}
        wide
      >
        {open !== null && (
          <Diff
            post={snap.post}
            number={open}
            canRestore={!disabled}
            before={() => draft.flush(false)}
            onRestored={(post) => {
              draft.accept(post);
              setOpen(null);
              onRestored();
            }}
          />
        )}
      </Dialog>
    </>
  );
}

const RUN = {
  same: "",
  add: "bg-success-soft text-success underline decoration-1",
  del: "bg-danger-soft text-danger line-through",
};
const Words = ({ words }: { words: { op: "same" | "add" | "del"; text: string }[] }) => (
  <span className="whitespace-pre-line">
    {words.map((w, i) => {
      const Tag = w.op === "add" ? "ins" : w.op === "del" ? "del" : "span";
      return (
        // biome-ignore lint/suspicious/noArrayIndexKey: runs never reorder
        <Tag key={i} className={RUN[w.op]}>
          {w.text}
        </Tag>
      );
    })}
  </span>
);
function Diff({
  post,
  number,
  canRestore,
  before,
  onRestored,
}: {
  post: Post;
  number: number;
  canRestore: boolean;
  before: () => Promise<boolean>;
  onRestored: (post: Post) => void;
}) {
  const t = useTranslations("content");
  const b = useTranslations("editor");
  const [pending, setPending] = useState(false);
  const [problem, setProblem] = useState<unknown>(null);
  const path = { post_id: post.id, number };
  const { data, error } = useQuery({
    queryKey: [...contentKeys.post(post.id), "diff", number],
    queryFn: () =>
      call(() => client.GET("/api/v1/posts/{post_id}/revisions/{number}/diff", { params: { path } })),
    staleTime: Number.POSITIVE_INFINITY,
  });
  if (error) return <FormError error={error} />;
  if (!data) return <Bone className="h-40 w-full" />;
  const nothing =
    !data.fields.length &&
    data.texts.every((x) => !x.fields.length && x.blocks.every((k) => k.op === "same"));
  return (
    <div className="flex flex-col gap-5">
      <FormError error={problem} />
      {nothing && <p className="text-text-secondary">{t("noChanges")}</p>}
      {data.fields.length > 0 && (
        <p>
          {t("changedDetails")}:{" "}
          {data.fields
            .map((f) => (t.has(`dataField.${f}` as never) ? t(`dataField.${f}` as never) : f))
            .join(", ")}
        </p>
      )}
      {data.texts.map((text) => (
        <section key={text.locale} className="flex flex-col gap-3">
          <h3 className="text-title">{t(`language.${text.locale}` as never)}</h3>
          {text.fields.map((f) => (
            <div key={f.field}>
              <p className="text-caption text-text-secondary">{t(`textField.${f.field}` as never)}</p>
              <p>
                <Words words={f.words} />
              </p>
            </div>
          ))}
          <ul className="flex flex-col gap-2">
            {text.blocks
              .filter((x) => x.op !== "same")
              .map((x) => (
                <li key={`${x.op}-${x.id}`} className="rounded-sm border border-border p-3">
                  <p className="text-caption text-text-secondary">
                    {t(`blockOp.${x.op}`)} · {b(`block.${x.type}` as never)}
                  </p>
                  <Words words={x.words} />
                </li>
              ))}
          </ul>
        </section>
      ))}
      {canRestore && (
        <Button
          variant="secondary"
          className="self-start"
          pending={pending}
          onClick={async () => {
            setPending(true);
            setProblem(null);
            try {
              if (!(await before())) return;
              onRestored(
                await call(() =>
                  client.POST("/api/v1/posts/{post_id}/revisions/{number}/restore", {
                    params: { path },
                    body: { version: post.version },
                  }),
                ),
              );
            } catch (err) {
              setProblem(err);
            } finally {
              setPending(false);
            }
          }}
        >
          <Check aria-hidden size={18} /> {t("restore", { n: number })}
        </Button>
      )}
    </div>
  );
}
