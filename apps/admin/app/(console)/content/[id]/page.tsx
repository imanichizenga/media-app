"use client";
import type { ContentDocument } from "@news/content-schema";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, Cloud, CloudOff, Eye, Radio, TriangleAlert } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useFormatter, useTranslations } from "next-intl";
import { useCallback, useEffect, useMemo, useState, useSyncExternalStore } from "react";
import { blank } from "@/components/editor/blocks";
import { BodyEditor, CardDialog, RenderContext } from "@/components/editor/body-editor";
import {
  DetailsPanel,
  EngagementPanel,
  HistoryPanel,
  PublishPanel,
  SeoPanel,
} from "@/components/editor/panels";
import { Preview } from "@/components/editor/preview";
import { Bone, Button, cx, ErrorState, Notice, useErrorText } from "@/components/ui";
import { ApiError, call, client } from "@/lib/api";
import { Draft, type Locale, type Post } from "@/lib/editor/draft";
import { contentKeys, useSignal } from "@/lib/queries";

const PANELS = ["publish", "details", "seo", "engagement", "history"] as const;
const EMPTY: ContentDocument = { version: 1, blocks: [] };
const HEARTBEAT = 25_000;

export default function EditorPage() {
  const { id } = useParams<{ id: string }>();
  const queries = useQueryClient();
  // One read per visit: from here on the draft owns the truth and asks for nothing it would overwrite.
  const { data, error, refetch } = useQuery({
    queryKey: [...contentKeys.post(id), "open"],
    queryFn: () => call(() => client.GET("/api/v1/posts/{post_id}", { params: { path: { post_id: id } } })),
    staleTime: Number.POSITIVE_INFINITY,
    gcTime: 0,
    refetchOnWindowFocus: false,
    refetchOnReconnect: false,
  });
  if (error) return <ErrorState error={error} retry={refetch} />;
  if (!data) return <Skeleton />;
  return (
    <Editor
      key={data.id}
      post={data}
      reload={async () => {
        await queries.resetQueries({ queryKey: [...contentKeys.post(id), "open"] });
      }}
    />
  );
}

function Editor({ post: initial, reload }: { post: Post; reload: () => Promise<void> }) {
  const t = useTranslations("content");
  const e = useTranslations("editor");
  const text = useErrorText();
  const format = useFormatter();
  const queries = useQueryClient();
  const path = useMemo(() => ({ params: { path: { post_id: initial.id } } }), [initial.id]);
  const [draft] = useState(
    () =>
      new Draft(initial, {
        save: (version, data, autosave) =>
          call(() =>
            client.PUT("/api/v1/posts/{post_id}", { ...path, body: { version, data, autosave, note: "" } }),
          ),
      }),
  );
  const snap = useSyncExternalStore(draft.subscribe, draft.get, draft.get);
  const { post, data, state } = snap;
  const [locale, setLocale] = useState<Locale>(data.texts?.sw || !data.texts?.en ? "sw" : "en");
  const [panel, setPanel] = useState<(typeof PANELS)[number]>("publish");
  const [generation, setGeneration] = useState(0); // a restore replaces the text under the editor
  const [preview, setPreview] = useState(false);
  const [live, setLive] = useState(false);
  const [holder, setHolder] = useState(initial.editing?.display_name ?? "");
  const editable = post.can_edit && !holder && state !== "conflict";

  // The soft lock: taken when the page opens, kept while it is open, given back when it closes.
  const lock = useCallback(
    async (force = false) => {
      try {
        await call(() => client.POST("/api/v1/posts/{post_id}/lock", { ...path, body: { force } }));
        setHolder("");
        return true;
      } catch (err) {
        if (err instanceof ApiError && err.code === "locked") setHolder(String(err.extra.holder ?? "…"));
        return false;
      }
    },
    [path],
  );
  useEffect(() => {
    if (!post.can_edit) return;
    void lock();
    const beat = setInterval(() => void lock(), HEARTBEAT);
    const leave = () => void client.DELETE("/api/v1/posts/{post_id}/lock", { ...path, keepalive: true });
    addEventListener("pagehide", leave);
    return () => {
      clearInterval(beat);
      removeEventListener("pagehide", leave);
    };
  }, [post.can_edit, lock, path]);

  // Leaving: send what is typed; warn only if it could not be sent.
  useEffect(() => {
    const warn = (event: BeforeUnloadEvent) => {
      if (!draft.dirty) return;
      void draft.flush(true);
      event.preventDefault();
    };
    addEventListener("beforeunload", warn);
    return () => {
      removeEventListener("beforeunload", warn);
      // In this order: a save takes the lock again.
      void draft
        .flush(true)
        .then(() => call(() => client.DELETE("/api/v1/posts/{post_id}/lock", path)))
        .catch(() => {})
        .finally(() => queries.invalidateQueries({ queryKey: contentKeys.posts }));
    };
  }, [draft, queries, path]);
  useEffect(() => {
    const save = (event: KeyboardEvent) => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "s") {
        event.preventDefault();
        void draft.flush(false);
      }
    };
    addEventListener("keydown", save);
    return () => removeEventListener("keydown", save);
  }, [draft]);
  useSignal(`post:${initial.id}`, ["posts", initial.id, "notes"]);

  const labels = useMemo(
    () => ({
      play: e("render.play"),
      playError: e("render.playError"),
      sensitive: e("render.sensitive"),
      readAlso: e("render.readAlso"),
      openPost: e("render.openPost"),
      unsupported: e("render.unsupported"),
      pinned: e("render.pinned"),
      gallery: e("render.gallery"),
    }),
    [e],
  );
  const formatTime = useCallback(
    (iso: string) => format.dateTime(new Date(iso), { timeStyle: "short", dateStyle: "short" }),
    [format],
  );
  const render = useMemo(
    () => ({ links: {}, mediaBase: "", labels, interactive: false, formatTime }),
    [labels, formatTime],
  );
  const words = data.texts?.[locale] ?? {};
  const props = { draft, snap, locale, disabled: !editable };
  const Status =
    state === "offline" ? CloudOff : state === "conflict" || state === "invalid" ? TriangleAlert : Cloud;

  return (
    <RenderContext value={render}>
      <header className="mb-4 flex flex-wrap items-center gap-2">
        <Link
          href="/content"
          aria-label={t("back")}
          className="tap grid w-11 place-items-center rounded-sm hover:bg-surface-sunken"
        >
          <ArrowLeft aria-hidden size={20} />
        </Link>
        <h1 className="sr-only">{words.headline || t("untitled")}</h1>
        <p
          role="status"
          className={cx(
            "flex flex-1 items-center gap-2 text-label",
            state === "invalid" || state === "conflict" ? "text-danger" : "text-text-secondary",
          )}
        >
          <Status aria-hidden size={18} /> {t(`save.${state}`)}
        </p>
        {data.type === "live_blog" && post.status === "published" && editable && (
          <Button variant="secondary" onClick={() => setLive(true)}>
            <Radio aria-hidden size={18} /> {t("liveUpdate")}
          </Button>
        )}
        <Button
          variant="secondary"
          onClick={async () => {
            await draft.flush(true);
            setPreview(true);
          }}
        >
          <Eye aria-hidden size={18} /> {t("preview")}
        </Button>
      </header>
      <div className="mb-4 flex flex-col gap-3 empty:hidden">
        {holder && (
          <Notice tone="warning">
            <p>{t("lockedBy", { name: holder })}</p>
            {post.can_edit && (
              <Button
                variant="secondary"
                className="mt-2"
                onClick={async () => (await lock(true)) && draft.unlock()}
              >
                {t("takeOver")}
              </Button>
            )}
          </Notice>
        )}
        {!post.can_edit && <Notice tone="warning">{t("readOnly")}</Notice>}
        {state === "conflict" && (
          <Notice tone="danger">
            <p>{t("conflict")}</p>
            <Button variant="secondary" className="mt-2" onClick={reload}>
              {t("reload")}
            </Button>
          </Notice>
        )}
        {state === "invalid" && <Notice tone="danger">{text(snap.error)}</Notice>}
      </div>
      <div className="grid items-start gap-6 xl:grid-cols-[minmax(0,1fr)_23rem]">
        <div className="flex min-w-0 flex-col gap-4">
          <div role="tablist" aria-label={t("languages")} className="flex gap-2">
            {(["sw", "en"] as const).map((l) => (
              <button
                key={l}
                type="button"
                role="tab"
                aria-selected={locale === l}
                onClick={() => setLocale(l)}
                className={cx(
                  "tap rounded-sm px-4 text-label",
                  locale === l ? "bg-accent-soft text-accent" : "text-text-secondary hover:bg-surface-sunken",
                )}
              >
                {t(`language.${l}`)}
                {!data.texts?.[l]?.headline && (
                  <span className="text-text-tertiary"> · {t("notStarted")}</span>
                )}
              </button>
            ))}
          </div>
          <textarea
            aria-label={t("headline")}
            placeholder={t("headline")}
            lang={locale}
            rows={1}
            maxLength={200}
            readOnly={!editable}
            value={words.headline ?? ""}
            onChange={(x) => draft.changeText(locale, { headline: x.target.value.replace(/\n/g, " ") })}
            className="field-sizing-content w-full resize-none bg-transparent font-serif text-headline-l outline-none placeholder:text-text-tertiary"
          />
          <textarea
            aria-label={t("standfirst")}
            placeholder={t("standfirst")}
            lang={locale}
            rows={1}
            maxLength={400}
            readOnly={!editable}
            value={words.standfirst ?? ""}
            onChange={(x) => draft.changeText(locale, { standfirst: x.target.value.replace(/\n/g, " ") })}
            className="field-sizing-content w-full resize-none bg-transparent text-body-l text-text-secondary outline-none placeholder:text-text-tertiary"
          />
          <BodyEditor
            key={`${locale}-${generation}`}
            locale={locale}
            initial={
              (words.body as ContentDocument | undefined)?.blocks ? (words.body as ContentDocument) : EMPTY
            }
            editable={editable}
            isLiveBlog={data.type === "live_blog"}
            onChange={(body) => draft.changeText(locale, { body: body as never })}
          />
        </div>
        <aside className="rounded-md border border-border bg-surface xl:sticky xl:top-4 xl:max-h-[calc(100dvh-2rem)] xl:overflow-y-auto">
          <div
            role="tablist"
            aria-label={t("panels")}
            className="flex overflow-x-auto border-border border-b"
          >
            {PANELS.map((p) => (
              <button
                key={p}
                type="button"
                role="tab"
                id={`tab-${p}`}
                aria-controls="panel"
                aria-selected={panel === p}
                onClick={() => setPanel(p)}
                className={cx(
                  "tap shrink-0 px-3 text-label",
                  panel === p
                    ? "border-accent border-b-2 text-accent"
                    : "text-text-secondary hover:text-text-primary",
                )}
              >
                {t(`panel.${p}`)}
              </button>
            ))}
          </div>
          <div role="tabpanel" id="panel" aria-labelledby={`tab-${panel}`} className="p-4">
            {panel === "publish" && (
              <PublishPanel
                {...props}
                onDone={() => queries.invalidateQueries({ queryKey: contentKeys.posts })}
              />
            )}
            {panel === "details" && <DetailsPanel {...props} />}
            {panel === "seo" && <SeoPanel {...props} />}
            {panel === "engagement" && <EngagementPanel {...props} />}
            {panel === "history" && (
              <HistoryPanel {...props} onRestored={() => setGeneration((n) => n + 1)} />
            )}
          </div>
        </aside>
      </div>
      <Preview
        post={post}
        locale={locale}
        open={preview}
        onClose={() => setPreview(false)}
        labels={labels}
        formatTime={formatTime}
      />
      <LiveComposer
        open={live}
        onClose={() => setLive(false)}
        send={async (block) => {
          if (!(await draft.flush(false))) return;
          const { type: _type, time: _time, ...rest } = block as Record<string, unknown>;
          const saved = await call(() =>
            client.POST("/api/v1/posts/{post_id}/live-updates", {
              ...path,
              body: { version: draft.get().post.version, locale, block: rest, publish: true },
            }),
          );
          draft.accept(saved);
          setGeneration((n) => n + 1);
          setLive(false);
        }}
      />
    </RenderContext>
  );
}

function LiveComposer({
  open,
  onClose,
  send,
}: {
  open: boolean;
  onClose: () => void;
  send: (block: object) => Promise<void>;
}) {
  const t = useTranslations("content");
  const text = useErrorText();
  const [block, setBlock] = useState(() => blank("live_update"));
  const [problem, setProblem] = useState<unknown>(null);
  useEffect(() => {
    if (!open) return;
    setBlock(blank("live_update"));
    setProblem(null);
  }, [open]);
  return (
    <>
      {problem !== null && <Notice tone="danger">{text(problem)}</Notice>}
      <CardDialog
        block={block}
        name={t("liveUpdate")}
        open={open}
        onClose={onClose}
        saveLabel={t("publishUpdate")}
        onSave={(next) => void send(next).catch(setProblem)}
      />
    </>
  );
}

function Skeleton() {
  return (
    <div aria-hidden>
      <div className="mb-4 flex items-center gap-2">
        <span className="tap bone w-11" />
        <span className="flex-1 text-label">
          <Bone className="w-24" />
        </span>
        <span className="tap bone w-32" />
      </div>
      <div className="grid items-start gap-6 xl:grid-cols-[minmax(0,1fr)_23rem]">
        <div className="flex min-w-0 flex-col gap-4">
          <div className="flex gap-2">
            <span className="tap bone w-28" />
            <span className="tap bone w-28" />
          </div>
          <p className="font-serif text-headline-l">
            <Bone className="w-3/4" />
          </p>
          <p className="text-body-l">
            <Bone className="w-full" />
          </p>
          <div className="rounded-md border border-border bg-surface">
            <div className="tap border-border border-b" />
            <BodyEditor.Skeleton />
          </div>
        </div>
        <div className="rounded-md border border-border bg-surface p-4" data-skeleton="panel">
          {[0, 1, 2, 3, 4].map((i) => (
            <span key={i} className="tap bone mb-3 block! w-full" />
          ))}
        </div>
      </div>
    </div>
  );
}
