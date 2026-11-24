"use client";
import type { Block, Inline, LiveBlock } from "@news/content-schema";
import { useQuery } from "@tanstack/react-query";
import {
  ArrowDown,
  ArrowUp,
  BadgeInfo,
  ChartBar,
  Clock,
  Film,
  GalleryHorizontalEnd,
  ImageIcon,
  Link as LinkIcon,
  ListChecks,
  type LucideIcon,
  MessageSquareQuote,
  Quote,
  Share2,
  Table as TableIcon,
  Trash2,
  Video,
} from "lucide-react";
import { useTranslations } from "next-intl";
import { createContext, type ReactNode, useContext, useState } from "react";
import { MediaPicker, Thumb } from "@/components/media/library";
import { Button, cx, Field, FormError, TextField } from "@/components/ui";
import { call, client } from "@/lib/api";
import { newId } from "@/lib/editor/convert";
import { useAsset } from "@/lib/queries";
import type { Asset } from "@/lib/upload";
import { InlineField } from "./inline-field";

/** Which language is being written: alternative text and pickers follow it. */
export const EditorLocale = createContext<"sw" | "en">("sw");

type Of<K extends Block["type"]> = Extract<Block, { type: K }>;
type FormProps<K extends Block["type"]> = { block: Of<K>; onChange: (block: Of<K>) => void };
export type CardKind = Exclude<Block["type"], "paragraph" | "heading" | "list">;

export const KINDS: Record<CardKind, LucideIcon> = {
  image: ImageIcon,
  gallery: GalleryHorizontalEnd,
  video: Film,
  youtube: Video,
  quote: Quote,
  pull_quote: MessageSquareQuote,
  callout: BadgeInfo,
  factbox: ListChecks,
  table: TableIcon,
  embed: Share2,
  related_link: LinkIcon,
  poll: ChartBar,
  live_update: Clock,
};

/** A new card, incomplete until its form is. */
export function blank(type: CardKind): Block {
  const id = newId();
  const items = (n: number) => Array.from({ length: n }, () => ({ content: [] as Inline[] }));
  switch (type) {
    case "image":
      return { type, id, asset: "", alt: "" };
    case "gallery":
      return { type, id, items: [], layout: "carousel" };
    case "video":
      return { type, id, asset: "" };
    case "youtube":
      return { type, id, videoId: "" };
    case "quote":
      return { type, id, content: [] };
    case "pull_quote":
      return { type, id, text: "" };
    case "callout":
      return { type, id, tone: "info", content: [] };
    case "factbox":
      return { type, id, title: "", items: items(3) };
    case "table":
      return {
        type,
        id,
        header: true,
        rows: Array.from({ length: 3 }, () => ({ cells: items(2) })),
      };
    case "embed":
      return { type, id, provider: "x", url: "" };
    case "related_link":
      return { type, id, title: "" };
    case "poll":
      return {
        type,
        id,
        question: "",
        options: [
          { id: newId(), label: "" },
          { id: newId(), label: "" },
        ],
      };
    case "live_update":
      // Ready to type: in a live blog seconds count.
      return {
        type,
        id,
        time: new Date().toISOString(),
        blocks: [{ type: "paragraph", id: newId(), content: [] }],
      };
  }
}

/** Empty optional fields are left out, so the stored document says only what was said. */
export function tidy(block: Block): Block {
  const drop = (o: object) =>
    Object.fromEntries(
      Object.entries(o).filter(
        ([, v]) => v !== "" && v !== undefined && !(Array.isArray(v) && v.length === 0),
      ),
    );
  switch (block.type) {
    case "image":
      return { ...(drop(block) as Of<"image">), alt: block.alt.trim() };
    case "gallery":
      return { ...block, items: block.items.map((i) => ({ ...(drop(i) as typeof i), alt: i.alt.trim() })) };
    case "quote":
    case "callout":
      return { ...(drop(block) as typeof block), content: block.content };
    case "factbox":
      return { ...block, items: block.items.filter((i) => i.content.length) };
    case "poll":
      return { ...(drop(block) as typeof block), options: block.options.filter((o) => o.label.trim()) };
    case "table":
    case "live_update":
      return block.type === "table"
        ? { ...(drop(block) as typeof block), header: block.header, rows: block.rows }
        : {
            ...(drop(block) as typeof block),
            blocks: block.blocks
              .map((b) => tidy(b) as LiveBlock)
              .filter((b) => b.type !== "paragraph" || b.content.length > 0),
          };
    default:
      return drop(block) as Block;
  }
}

// ---- pieces ----
function AssetField({
  id,
  kind,
  onPick,
}: {
  id: string;
  kind: "image" | "video";
  onPick: (asset: Asset) => void;
}) {
  const t = useTranslations("editor");
  const { data } = useAsset(id || null);
  const [open, setOpen] = useState(false);
  return (
    <div className="flex items-center gap-4">
      {data && <Thumb asset={data.asset} className="aspect-4/3 w-32 shrink-0" />}
      <Button variant="secondary" onClick={() => setOpen(true)}>
        {t(id ? "change" : `choose.${kind}`)}
      </Button>
      <MediaPicker kind={kind} open={open} onClose={() => setOpen(false)} onPick={onPick} />
    </div>
  );
}
const altOf = (asset: Asset, locale: "sw" | "en") => (locale === "en" ? asset.alt_en : asset.alt_sw);

const Check = ({
  label,
  checked,
  onChange,
}: {
  label: string;
  checked: boolean;
  onChange: (on: boolean) => void;
}) => (
  <label className="tap flex items-center gap-3 text-label">
    <input
      type="checkbox"
      checked={checked}
      onChange={(e) => onChange(e.target.checked)}
      className="size-5"
    />
    {label}
  </label>
);

function Choice<T extends string>({
  label,
  value,
  options,
  onChange,
}: {
  label: string;
  value: T;
  options: [T, string][];
  onChange: (value: T) => void;
}) {
  return (
    <Field label={label}>
      {(p) => (
        <select {...p} value={value} onChange={(e) => onChange(e.target.value as T)}>
          {options.map(([key, text]) => (
            <option key={key} value={key}>
              {text}
            </option>
          ))}
        </select>
      )}
    </Field>
  );
}

/** Move and remove, by buttons that work for everyone. */
function Order({
  label,
  first,
  last,
  move,
  remove,
}: {
  label: string;
  first: boolean;
  last: boolean;
  move: (by: -1 | 1) => void;
  remove: () => void;
}) {
  const t = useTranslations("editor");
  const button = "tap grid w-11 place-items-center rounded-sm hover:bg-surface-sunken disabled:opacity-30";
  return (
    <span className="flex shrink-0">
      <button
        type="button"
        className={button}
        disabled={first}
        onClick={() => move(-1)}
        aria-label={t("up", { label })}
      >
        <ArrowUp aria-hidden size={18} />
      </button>
      <button
        type="button"
        className={button}
        disabled={last}
        onClick={() => move(1)}
        aria-label={t("down", { label })}
      >
        <ArrowDown aria-hidden size={18} />
      </button>
      <button type="button" className={button} onClick={remove} aria-label={t("remove", { label })}>
        <Trash2 aria-hidden size={18} />
      </button>
    </span>
  );
}
export function moved<T>(list: T[], from: number, by: -1 | 1): T[] {
  const next = [...list];
  const [item] = next.splice(from, 1);
  if (item !== undefined) next.splice(from + by, 0, item);
  return next;
}
const replaced = <T,>(list: T[], at: number, value: T) => list.map((v, i) => (i === at ? value : v));
const without = <T,>(list: T[], at: number) => list.filter((_, i) => i !== at);

// ---- forms ----
function ImageForm({ block, onChange }: FormProps<"image">) {
  const t = useTranslations("editor");
  const locale = useContext(EditorLocale);
  return (
    <>
      <AssetField
        id={block.asset}
        kind="image"
        onPick={(a) => onChange({ ...block, asset: a.id, alt: block.alt || altOf(a, locale) })}
      />
      <TextField
        label={t("alt")}
        help={t("altHelp")}
        value={block.alt}
        maxLength={500}
        required
        onChange={(e) => onChange({ ...block, alt: e.target.value })}
      />
      <InlineField
        label={t("caption")}
        value={block.caption ?? []}
        onChange={(caption) => onChange({ ...block, caption })}
      />
      <TextField
        label={t("creditOverride")}
        value={block.credit ?? ""}
        maxLength={200}
        onChange={(e) => onChange({ ...block, credit: e.target.value })}
      />
      <Choice
        label={t("layout")}
        value={block.layout ?? "normal"}
        options={(["normal", "wide", "full"] as const).map((k) => [k, t(`layouts.${k}`)])}
        onChange={(layout) => onChange({ ...block, layout })}
      />
      <Check
        label={t("sensitive")}
        checked={block.sensitive ?? false}
        onChange={(sensitive) => onChange({ ...block, sensitive })}
      />
    </>
  );
}

function GalleryForm({ block, onChange }: FormProps<"gallery">) {
  const t = useTranslations("editor");
  const locale = useContext(EditorLocale);
  const [open, setOpen] = useState(false);
  const set = (items: typeof block.items) => onChange({ ...block, items });
  return (
    <>
      <ul className="flex flex-col gap-3">
        {block.items.map((item, i) => (
          <li
            // biome-ignore lint/suspicious/noArrayIndexKey: the same picture may appear twice
            key={`${item.asset}-${i}`}
            className="flex flex-wrap items-end gap-3 rounded-sm border border-border p-3"
          >
            <GalleryThumb id={item.asset} />
            <div className="min-w-48 flex-1">
              <TextField
                label={t("alt")}
                value={item.alt}
                maxLength={500}
                required
                onChange={(e) => set(replaced(block.items, i, { ...item, alt: e.target.value }))}
              />
            </div>
            <Order
              label={t("picture", { n: i + 1 })}
              first={i === 0}
              last={i === block.items.length - 1}
              move={(by) => set(moved(block.items, i, by))}
              remove={() => set(without(block.items, i))}
            />
          </li>
        ))}
      </ul>
      {block.items.length < 60 && (
        <Button variant="secondary" className="self-start" onClick={() => setOpen(true)}>
          {t("addPicture")}
        </Button>
      )}
      <MediaPicker
        kind="image"
        open={open}
        onClose={() => setOpen(false)}
        onPick={(a) => set([...block.items, { asset: a.id, alt: altOf(a, locale) }])}
      />
      <Choice
        label={t("layout")}
        value={block.layout ?? "carousel"}
        options={(["carousel", "grid"] as const).map((k) => [k, t(`layouts.${k}`)])}
        onChange={(layout) => onChange({ ...block, layout })}
      />
    </>
  );
}
function GalleryThumb({ id }: { id: string }) {
  const { data } = useAsset(id);
  return data ? (
    <Thumb asset={data.asset} className="aspect-4/3 w-20" />
  ) : (
    <span className="bone aspect-4/3 w-20" />
  );
}

function VideoForm({ block, onChange }: FormProps<"video">) {
  const t = useTranslations("editor");
  return (
    <>
      <AssetField id={block.asset} kind="video" onPick={(a) => onChange({ ...block, asset: a.id })} />
      <InlineField
        label={t("caption")}
        value={block.caption ?? []}
        onChange={(caption) => onChange({ ...block, caption })}
      />
      <Check
        label={t("sensitive")}
        checked={block.sensitive ?? false}
        onChange={(sensitive) => onChange({ ...block, sensitive })}
      />
    </>
  );
}

export async function importYouTube(url: string) {
  return call(() => client.POST("/api/v1/media/youtube", { body: { url } }));
}
function YouTubeForm({ block, onChange }: FormProps<"youtube">) {
  const t = useTranslations("editor");
  const [url, setUrl] = useState(block.videoId ? `https://youtu.be/${block.videoId}` : "");
  const [problem, setProblem] = useState<unknown>(null);
  const [pending, setPending] = useState(false);
  const read = async () => {
    setPending(true);
    setProblem(null);
    try {
      const v = await importYouTube(url);
      onChange({
        ...block,
        videoId: v.video_id,
        title: v.title,
        start: v.start || undefined,
        vertical: v.vertical || undefined,
      });
    } catch (err) {
      setProblem(err);
    } finally {
      setPending(false);
    }
  };
  return (
    <>
      <FormError error={problem} />
      <div className="flex items-end gap-2">
        <div className="flex-1">
          <TextField
            label={t("youtubeUrl")}
            help={t("youtubeHelp")}
            value={url}
            onChange={(e) => setUrl(e.target.value)}
          />
        </div>
      </div>
      <Button variant="secondary" className="self-start" pending={pending} disabled={!url} onClick={read}>
        {t("youtubeRead")}
      </Button>
      {block.videoId && (
        <TextField
          label={t("title")}
          value={block.title ?? ""}
          maxLength={300}
          onChange={(e) => onChange({ ...block, title: e.target.value })}
        />
      )}
    </>
  );
}

function QuoteForm({ block, onChange }: FormProps<"quote">) {
  const t = useTranslations("editor");
  return (
    <>
      <InlineField
        label={t("quoteText")}
        value={block.content}
        onChange={(content) => onChange({ ...block, content })}
      />
      <TextField
        label={t("attribution")}
        value={block.attribution ?? ""}
        maxLength={200}
        onChange={(e) => onChange({ ...block, attribution: e.target.value })}
      />
    </>
  );
}
function PullQuoteForm({ block, onChange }: FormProps<"pull_quote">) {
  const t = useTranslations("editor");
  return (
    <>
      <TextField
        label={t("quoteText")}
        value={block.text}
        maxLength={400}
        required
        onChange={(e) => onChange({ ...block, text: e.target.value })}
      />
      <TextField
        label={t("attribution")}
        value={block.attribution ?? ""}
        maxLength={200}
        onChange={(e) => onChange({ ...block, attribution: e.target.value })}
      />
    </>
  );
}
function CalloutForm({ block, onChange }: FormProps<"callout">) {
  const t = useTranslations("editor");
  return (
    <>
      <Choice
        label={t("tone")}
        value={block.tone}
        options={(["info", "warning", "success"] as const).map((k) => [k, t(`tones.${k}`)])}
        onChange={(tone) => onChange({ ...block, tone })}
      />
      <TextField
        label={t("title")}
        value={block.title ?? ""}
        maxLength={160}
        onChange={(e) => onChange({ ...block, title: e.target.value })}
      />
      <InlineField
        label={t("text")}
        value={block.content}
        onChange={(content) => onChange({ ...block, content })}
      />
    </>
  );
}
function FactboxForm({ block, onChange }: FormProps<"factbox">) {
  const t = useTranslations("editor");
  const set = (items: typeof block.items) => onChange({ ...block, items });
  return (
    <>
      <TextField
        label={t("title")}
        value={block.title}
        maxLength={160}
        required
        onChange={(e) => onChange({ ...block, title: e.target.value })}
      />
      <ul className="flex flex-col gap-2">
        {block.items.map((item, i) => (
          // biome-ignore lint/suspicious/noArrayIndexKey: facts have no id; length changes remount on purpose
          <li key={`${block.items.length}-${i}`} className="flex items-center gap-2">
            <div className="min-w-0 flex-1">
              <InlineField
                compact
                label={t("fact", { n: i + 1 })}
                value={item.content}
                onChange={(content) => set(replaced(block.items, i, { content }))}
              />
            </div>
            <Order
              label={t("fact", { n: i + 1 })}
              first={i === 0}
              last={i === block.items.length - 1}
              move={(by) => set(moved(block.items, i, by))}
              remove={() => set(without(block.items, i))}
            />
          </li>
        ))}
      </ul>
      <Button
        variant="secondary"
        className="self-start"
        onClick={() => set([...block.items, { content: [] }])}
      >
        {t("addFact")}
      </Button>
    </>
  );
}
function TableForm({ block, onChange }: FormProps<"table">) {
  const t = useTranslations("editor");
  const width = block.rows[0]?.cells.length ?? 1;
  const set = (rows: typeof block.rows) => onChange({ ...block, rows });
  const empty = () => ({ content: [] as Inline[] });
  return (
    <>
      <TextField
        label={t("caption")}
        value={block.caption ?? ""}
        maxLength={300}
        onChange={(e) => onChange({ ...block, caption: e.target.value })}
      />
      <Check
        label={t("headerRow")}
        checked={block.header}
        onChange={(header) => onChange({ ...block, header })}
      />
      <div className="overflow-x-auto">
        <div
          className="grid min-w-max gap-2"
          style={{ gridTemplateColumns: `repeat(${width}, minmax(9rem, 1fr))` }}
        >
          {block.rows.map((row, r) =>
            row.cells.map((cell, k) => (
              <InlineField
                // biome-ignore lint/suspicious/noArrayIndexKey: a grid position is its identity
                key={`${block.rows.length}-${width}-${r}-${k}`}
                compact
                label={t("cell", { r: r + 1, c: k + 1 })}
                value={cell.content}
                onChange={(content) =>
                  set(replaced(block.rows, r, { cells: replaced(row.cells, k, { content }) }))
                }
              />
            )),
          )}
        </div>
      </div>
      <div className="flex flex-wrap gap-2">
        <Button
          variant="secondary"
          disabled={block.rows.length >= 200}
          onClick={() => set([...block.rows, { cells: Array.from({ length: width }, empty) }])}
        >
          {t("addRow")}
        </Button>
        <Button
          variant="secondary"
          disabled={block.rows.length < 2}
          onClick={() => set(block.rows.slice(0, -1))}
        >
          {t("removeRow")}
        </Button>
        <Button
          variant="secondary"
          disabled={width >= 12}
          onClick={() => set(block.rows.map((row) => ({ cells: [...row.cells, empty()] })))}
        >
          {t("addColumn")}
        </Button>
        <Button
          variant="secondary"
          disabled={width < 2}
          onClick={() => set(block.rows.map((row) => ({ cells: row.cells.slice(0, -1) })))}
        >
          {t("removeColumn")}
        </Button>
      </div>
    </>
  );
}
const PROVIDERS: Record<string, Of<"embed">["provider"]> = {
  "x.com": "x",
  "twitter.com": "x",
  "instagram.com": "instagram",
  "facebook.com": "facebook",
  "tiktok.com": "tiktok",
};
export function providerOf(url: string): Of<"embed">["provider"] | null {
  try {
    const host = new URL(url).hostname.replace(/^(www|m|web|mobile)\./, "");
    return PROVIDERS[host] ?? null;
  } catch {
    return null;
  }
}
function EmbedForm({ block, onChange }: FormProps<"embed">) {
  const t = useTranslations("editor");
  return (
    <>
      <TextField
        label={t("embedUrl")}
        help={t("embedHelp")}
        value={block.url}
        required
        error={block.url && !providerOf(block.url) ? t("embedBad") : undefined}
        onChange={(e) => {
          const url = e.target.value.trim();
          onChange({ ...block, url, provider: providerOf(url) ?? block.provider });
        }}
      />
      <TextField
        label={t("embedAuthor")}
        value={block.author ?? ""}
        maxLength={120}
        onChange={(e) => onChange({ ...block, author: e.target.value })}
      />
      <Field label={t("embedText")}>
        {(p) => (
          <textarea
            {...p}
            rows={4}
            maxLength={2000}
            value={block.text ?? ""}
            onChange={(e) => onChange({ ...block, text: e.target.value })}
          />
        )}
      </Field>
    </>
  );
}
function RelatedForm({ block, onChange }: FormProps<"related_link">) {
  const t = useTranslations("editor");
  const [q, setQ] = useState("");
  const found = useQuery({
    queryKey: ["posts", "picker", q],
    queryFn: () =>
      call(() => client.GET("/api/v1/posts", { params: { query: { q, status: ["published"] } } })),
    enabled: q.length > 2,
  });
  return (
    <>
      <TextField label={t("findPost")} value={q} onChange={(e) => setQ(e.target.value)} type="search" />
      {found.data && (
        <ul className="flex max-h-56 flex-col overflow-y-auto rounded-sm border border-border">
          {found.data.results.map((post) => (
            <li key={post.id}>
              <button
                type="button"
                className={cx(
                  "tap w-full px-3 text-left hover:bg-surface-sunken",
                  block.post === post.id && "bg-brand-soft text-brand-text",
                )}
                onClick={() =>
                  onChange({ ...block, post: post.id, url: undefined, title: block.title || post.headline })
                }
              >
                {post.headline}
              </button>
            </li>
          ))}
        </ul>
      )}
      <TextField
        label={t("title")}
        value={block.title}
        maxLength={300}
        required
        onChange={(e) => onChange({ ...block, title: e.target.value })}
      />
      {!block.post && (
        <TextField
          label={t("orAddress")}
          value={block.url ?? ""}
          maxLength={2048}
          onChange={(e) => onChange({ ...block, url: e.target.value.trim() })}
        />
      )}
    </>
  );
}
function PollForm({ block, onChange }: FormProps<"poll">) {
  const t = useTranslations("editor");
  const set = (options: typeof block.options) => onChange({ ...block, options });
  return (
    <>
      <TextField
        label={t("question")}
        value={block.question}
        maxLength={300}
        required
        onChange={(e) => onChange({ ...block, question: e.target.value })}
      />
      <ul className="flex flex-col gap-2">
        {block.options.map((option, i) => (
          <li key={option.id} className="flex items-end gap-2">
            <div className="flex-1">
              <TextField
                label={t("option", { n: i + 1 })}
                value={option.label}
                maxLength={120}
                onChange={(e) => set(replaced(block.options, i, { ...option, label: e.target.value }))}
              />
            </div>
            <Order
              label={t("option", { n: i + 1 })}
              first={i === 0}
              last={i === block.options.length - 1}
              move={(by) => set(moved(block.options, i, by))}
              remove={() => set(without(block.options, i))}
            />
          </li>
        ))}
      </ul>
      {block.options.length < 10 && (
        <Button
          variant="secondary"
          className="self-start"
          onClick={() => set([...block.options, { id: newId(), label: "" }])}
        >
          {t("addOption")}
        </Button>
      )}
    </>
  );
}

const LIVE_KINDS = ["image", "video", "youtube", "quote", "embed"] as const;
/** An update is a few paragraphs and at most a handful of cards. */
export function LiveUpdateForm({ block, onChange }: FormProps<"live_update">) {
  const t = useTranslations("editor");
  const set = (blocks: LiveBlock[]) => onChange({ ...block, blocks });
  return (
    <>
      <TextField
        label={t("title")}
        value={block.title ?? ""}
        maxLength={200}
        onChange={(e) => onChange({ ...block, title: e.target.value })}
      />
      <ul className="flex flex-col gap-4">
        {block.blocks.map((inner, i) => (
          <li key={inner.id} className="flex flex-col gap-3 rounded-sm border border-border p-3">
            <div className="flex items-center justify-between">
              <span className="text-label text-text-secondary">{t(`block.${inner.type}` as never)}</span>
              <Order
                label={t(`block.${inner.type}` as never)}
                first={i === 0}
                last={i === block.blocks.length - 1}
                move={(by) => set(moved(block.blocks, i, by))}
                remove={() => set(without(block.blocks, i))}
              />
            </div>
            {inner.type === "paragraph" ? (
              <InlineField
                label={t("text")}
                value={inner.content}
                onChange={(content) => set(replaced(block.blocks, i, { ...inner, content }))}
              />
            ) : inner.type === "list" ? (
              <p>{t("listInUpdate", { n: inner.items.length })}</p>
            ) : (
              <BlockForm
                block={inner}
                onChange={(next) => set(replaced(block.blocks, i, next as LiveBlock))}
              />
            )}
          </li>
        ))}
      </ul>
      <div className="flex flex-wrap gap-2">
        <Button
          variant="secondary"
          onClick={() => set([...block.blocks, { type: "paragraph", id: newId(), content: [] }])}
        >
          {t("block.paragraph")}
        </Button>
        {LIVE_KINDS.map((kind) => (
          <Button
            key={kind}
            variant="secondary"
            onClick={() => set([...block.blocks, blank(kind) as LiveBlock])}
          >
            {t(`block.${kind}`)}
          </Button>
        ))}
      </div>
      <Check
        label={t("pinned")}
        checked={block.pinned ?? false}
        onChange={(pinned) => onChange({ ...block, pinned })}
      />
    </>
  );
}

const FORMS: { [K in CardKind]: (props: FormProps<K>) => ReactNode } = {
  image: ImageForm,
  gallery: GalleryForm,
  video: VideoForm,
  youtube: YouTubeForm,
  quote: QuoteForm,
  pull_quote: PullQuoteForm,
  callout: CalloutForm,
  factbox: FactboxForm,
  table: TableForm,
  embed: EmbedForm,
  related_link: RelatedForm,
  poll: PollForm,
  live_update: LiveUpdateForm,
};
export function BlockForm({ block, onChange }: { block: Block; onChange: (block: Block) => void }) {
  const Form = FORMS[block.type as CardKind] as unknown as (props: FormProps<never>) => ReactNode;
  return Form ? <Form block={block as never} onChange={onChange as never} /> : null;
}
