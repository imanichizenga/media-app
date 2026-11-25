"use client";
import type { ContentDocument } from "@news/content-schema";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useFormatter, useTranslations } from "next-intl";
import { useCallback, useEffect, useMemo, useState } from "react";
import { BodyEditor, RenderContext } from "@/components/editor/body-editor";
import { Bone, Button, Card, cx, Dialog, ErrorState, Notice, TextField, useErrorText } from "@/components/ui";
import type { Schemas } from "@news/api-client/admin";
import { ApiError, call, client } from "@/lib/api";
import { keys } from "@/lib/queries";

type Detail = Schemas["PageDetail"];
type Locale = "sw" | "en";
type Text = { title: string; summary: string; body: ContentDocument };
type Texts = Record<Locale, Text>;
const EMPTY: ContentDocument = { version: 1, blocks: [] };
const textsOf = (texts: Detail["texts"]): Texts => {
  const one = (l: Locale): Text => ({
    title: texts[l]?.title ?? "",
    summary: texts[l]?.summary ?? "",
    body: (texts[l]?.body as ContentDocument | undefined)?.blocks
      ? (texts[l]?.body as ContentDocument)
      : EMPTY,
  });
  return { sw: one("sw"), en: one("en") };
};

export default function PageEditorPage() {
  const { key } = useParams<{ key: string }>();
  const { data, error, refetch } = useQuery({
    queryKey: keys.page(key),
    queryFn: () => call(() => client.GET("/api/v1/pages/{key}", { params: { path: { key } } })),
    // What is typed must not be replaced under the hand.
    staleTime: Number.POSITIVE_INFINITY,
    refetchOnWindowFocus: false,
    refetchOnReconnect: false,
  });
  if (error && !data) return <ErrorState error={error} retry={refetch} />;
  if (!data) return <Skeleton />;
  return <Editor key={key} initial={data} />;
}

function Editor({ initial }: { initial: Detail }) {
  const t = useTranslations("pages");
  const c = useTranslations("content");
  const e = useTranslations("editor");
  const format = useFormatter();
  const text = useErrorText();
  const queries = useQueryClient();
  const [page, setPage] = useState(initial);
  const [texts, setTexts] = useState(() => textsOf(initial.texts));
  const [locale, setLocale] = useState<Locale>("sw");
  const [note, setNote] = useState("");
  const [generation, setGeneration] = useState(0);
  const [dirty, setDirty] = useState(false);
  const [pending, setPending] = useState("");
  const [problem, setProblem] = useState<unknown>(null);
  const [notice, setNotice] = useState("");
  const [withdrawing, setWithdrawing] = useState(false);
  const path = useMemo(() => ({ params: { path: { key: page.key } } }), [page.key]);
  const words = texts[locale];
  const change = (part: Partial<Text>) => {
    setTexts((all) => ({ ...all, [locale]: { ...all[locale], ...part } }));
    setDirty(true);
    setNotice("");
  };
  useEffect(() => {
    const warn = (event: BeforeUnloadEvent) => dirty && event.preventDefault();
    addEventListener("beforeunload", warn);
    return () => removeEventListener("beforeunload", warn);
  }, [dirty]);

  async function run(what: string, work: () => Promise<Detail>, done: string) {
    setPending(what);
    setProblem(null);
    setNotice("");
    try {
      const next = await work();
      setPage(next);
      queries.setQueryData(keys.page(next.key), next);
      void queries.invalidateQueries({ queryKey: keys.pages, exact: true });
      setNotice(done);
      return next;
    } catch (err) {
      setProblem(err);
      return null;
    } finally {
      setPending("");
    }
  }
  const save = () =>
    run(
      "save",
      () =>
        call(() =>
          client.PUT("/api/v1/pages/{key}", {
            ...path,
            body: { version: page.version, texts: texts as never, note },
          }),
        ),
      t("saved"),
    ).then((next) => {
      if (next) {
        setDirty(false);
        setNote("");
      }
      return next;
    });
  const publish = (number: number) =>
    run(
      "publish",
      () => call(() => client.POST("/api/v1/pages/{key}/publish", { ...path, body: { number } })),
      t("published"),
    );
  const missing =
    problem instanceof ApiError && Array.isArray(problem.extra.missing) ? problem.extra.missing : [];
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
  const when = useCallback(
    (iso: string) => format.dateTime(new Date(iso), { dateStyle: "medium", timeStyle: "short" }),
    [format],
  );
  const render = useMemo(
    () => ({ links: {}, mediaBase: "", labels, interactive: false, formatTime: when }),
    [labels, when],
  );
  return (
    <RenderContext value={render}>
      <header className="mb-4 flex flex-wrap items-center gap-2">
        <Link
          href="/pages"
          aria-label={t("back")}
          className="tap grid w-11 place-items-center rounded-sm hover:bg-surface-sunken"
        >
          <ArrowLeft aria-hidden size={20} />
        </Link>
        <h1 className="flex-1 font-serif text-headline-m">{t(`key.${page.key}` as never)}</h1>
        <Button variant="secondary" pending={pending === "save"} disabled={!dirty} onClick={save}>
          {t("save")}
        </Button>
        <Button
          pending={pending === "publish"}
          onClick={async () => {
            const at = dirty ? await save() : page;
            if (at?.version) await publish(at.version);
          }}
        >
          {t("publish")}
        </Button>
      </header>
      <div role="status" className="mb-4 flex flex-col gap-3 empty:hidden">
        {notice && <Notice tone="success">{notice}</Notice>}
        {problem !== null && (
          <Notice tone="danger">
            <p>{text(problem)}</p>
            {missing.length > 0 && (
              <p>
                {t("missing", {
                  what: missing.map((m) => t(`part.${String(m).replace(".", "_")}` as never)).join(", "),
                })}
              </p>
            )}
          </Notice>
        )}
      </div>
      <div className="grid grid-cols-[minmax(0,1fr)] items-start gap-6 xl:grid-cols-[minmax(0,1fr)_23rem]">
        <div className="flex min-w-0 flex-col gap-4">
          <div role="tablist" aria-label={c("languages")} className="flex gap-2">
            {(["sw", "en"] as const).map((l) => (
              <button
                key={l}
                type="button"
                role="tab"
                aria-selected={locale === l}
                onClick={() => setLocale(l)}
                className={cx(
                  "tap rounded-sm px-4 text-label",
                  locale === l
                    ? "bg-brand-soft text-brand-text"
                    : "text-text-secondary hover:bg-surface-sunken",
                )}
              >
                {c(`language.${l}`)}
                {!texts[l].title && <span className="text-text-tertiary"> · {c("notStarted")}</span>}
              </button>
            ))}
          </div>
          <textarea
            aria-label={t("pageTitle")}
            placeholder={t("pageTitle")}
            lang={locale}
            rows={1}
            maxLength={120}
            value={words.title}
            onChange={(x) => change({ title: x.target.value.replace(/\n/g, " ") })}
            className="field-sizing-content w-full resize-none bg-transparent font-serif text-headline-l outline-none placeholder:text-text-tertiary"
          />
          <textarea
            aria-label={t("summary")}
            placeholder={t("summary")}
            lang={locale}
            rows={1}
            maxLength={300}
            value={words.summary}
            onChange={(x) => change({ summary: x.target.value.replace(/\n/g, " ") })}
            className="field-sizing-content w-full resize-none bg-transparent text-body-l text-text-secondary outline-none placeholder:text-text-tertiary"
          />
          <BodyEditor
            key={`${locale}-${generation}`}
            locale={locale}
            initial={words.body}
            editable
            isLiveBlog={false}
            onChange={(body) => change({ body })}
          />
        </div>
        <Card>
          <div className="flex flex-col gap-4">
            <TextField
              label={t("note")}
              name="note"
              maxLength={300}
              value={note}
              onChange={(x) => setNote(x.target.value)}
            />
            <h2 className="text-title">{t("history")}</h2>
            {page.revisions.length === 0 && <p className="text-text-secondary">{t("empty")}</p>}
            <ul className="flex flex-col divide-y divide-border">
              {page.revisions.map((r) => (
                <li key={r.number} className="flex flex-col gap-1 py-3">
                  <p className="text-label">
                    {t("revision", { n: r.number })}
                    {r.is_published && <span className="text-success"> · {t("live")}</span>}
                  </p>
                  <p className="text-caption text-text-secondary">
                    {r.author.display_name}, {when(r.created_at)}
                  </p>
                  {r.note && <p className="text-caption">{r.note}</p>}
                  <div className="flex flex-wrap gap-2">
                    <Button
                      variant="secondary"
                      disabled={Boolean(pending)}
                      onClick={async () => {
                        const old = await call(() =>
                          client.GET("/api/v1/pages/{key}/revisions/{number}", {
                            params: { path: { key: page.key, number: r.number } },
                          }),
                        ).catch((err) => setProblem(err));
                        if (!old) return;
                        setTexts(textsOf(old.texts));
                        setGeneration((n) => n + 1);
                        setDirty(true);
                      }}
                    >
                      {t("open")}
                    </Button>
                    {!r.is_published && (
                      <Button
                        variant="secondary"
                        disabled={Boolean(pending) || dirty}
                        onClick={() => publish(r.number)}
                      >
                        {t("publishThis")}
                      </Button>
                    )}
                  </div>
                </li>
              ))}
            </ul>
            {page.published_number !== null && (
              <Button variant="secondary" onClick={() => setWithdrawing(true)}>
                {t("withdraw")}
              </Button>
            )}
          </div>
        </Card>
      </div>
      <Dialog open={withdrawing} onClose={() => setWithdrawing(false)} title={t("withdraw")}>
        <p className="mb-4">{t("withdrawLead")}</p>
        <Button
          pending={pending === "withdraw"}
          onClick={async () => {
            await run(
              "withdraw",
              () => call(() => client.DELETE("/api/v1/pages/{key}/publish", path)),
              t("withdrawn"),
            );
            setWithdrawing(false);
          }}
        >
          {t("withdraw")}
        </Button>
      </Dialog>
    </RenderContext>
  );
}

function Skeleton() {
  return (
    <div aria-hidden>
      <div className="mb-4 flex items-center gap-2">
        <span className="tap bone w-11" />
        <span className="flex-1 font-serif text-headline-m">
          <Bone className="w-48" />
        </span>
        <span className="tap bone w-28" />
        <span className="tap bone w-28" />
      </div>
      <div className="grid grid-cols-[minmax(0,1fr)] items-start gap-6 xl:grid-cols-[minmax(0,1fr)_23rem]">
        <div className="flex min-w-0 flex-col gap-4">
          <div className="flex gap-2">
            <span className="tap bone w-28" />
            <span className="tap bone w-28" />
          </div>
          <p className="font-serif text-headline-l" data-skeleton="title">
            <Bone className="w-1/2" />
          </p>
          <p className="text-body-l">
            <Bone className="w-full" />
          </p>
          <div className="rounded-md border border-border bg-surface">
            <div className="tap border-border border-b" />
            <BodyEditor.Skeleton />
          </div>
        </div>
        <div className="rounded-md border border-border bg-surface p-4">
          {[0, 1, 2].map((i) => (
            <span key={i} className="tap bone mb-3 block! w-full" />
          ))}
        </div>
      </div>
    </div>
  );
}
