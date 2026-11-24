"use client";
import { ArticleBody, type ContentContext } from "@news/ui/content";
import { type ImageAsset, Picture } from "@news/ui/media";
import { useQuery } from "@tanstack/react-query";
import { Monitor, Smartphone } from "lucide-react";
import { useTranslations } from "next-intl";
import { useState } from "react";
import { Button, cx, Dialog, ErrorState } from "@/components/ui";
import { call, client } from "@/lib/api";
import type { Locale, Post } from "@/lib/editor/draft";

type Article = Pick<ContentContext, "assets" | "links"> & {
  headline: string;
  standfirst: string;
  body: unknown;
  category: { name: string };
  authors: { name: string }[];
  image: ImageAsset | null;
  reading_minutes: number;
  correction_note: string;
  update_note: string;
};

export function Preview({
  post,
  locale,
  open,
  onClose,
  labels,
  formatTime,
}: {
  post: Post;
  locale: Locale;
  open: boolean;
  onClose: () => void;
  labels: ContentContext["labels"];
  formatTime: (iso: string) => string;
}) {
  const t = useTranslations("content");
  const [phone, setPhone] = useState(true);
  const { data, error, refetch } = useQuery({
    queryKey: ["posts", post.id, "preview", locale, post.version],
    queryFn: () =>
      call(() =>
        client.GET("/api/v1/posts/{post_id}/preview", {
          params: { path: { post_id: post.id }, query: { locale } },
        }),
      ),
    enabled: open,
  });
  const article = data?.article as Article | undefined;
  const context: ContentContext | null =
    data && article
      ? {
          assets: article.assets,
          links: article.links,
          mediaBase: data.media_base_url,
          labels,
          interactive: false,
          formatTime,
        }
      : null;
  return (
    <Dialog open={open} onClose={onClose} title={t("preview")} wide>
      <div className="mb-4 flex gap-2">
        {[true, false].map((p) => (
          <Button
            key={String(p)}
            variant={phone === p ? "primary" : "secondary"}
            aria-pressed={phone === p}
            onClick={() => setPhone(p)}
          >
            {p ? <Smartphone aria-hidden size={18} /> : <Monitor aria-hidden size={18} />}
            {t(p ? "phone" : "desktop")}
          </Button>
        ))}
      </div>
      {error ? (
        <ErrorState error={error} retry={refetch} />
      ) : (
        <div
          lang={locale}
          className={cx(
            "mx-auto overflow-hidden rounded-lg border border-border bg-bg p-4",
            phone ? "max-w-[390px]" : "max-w-[720px]",
          )}
        >
          {article && context ? (
            <article className="flex flex-col gap-4">
              <p className="text-brand-text text-label">{article.category.name}</p>
              <h2 className={phone ? "text-headline-m" : "text-display"}>{article.headline}</h2>
              {article.standfirst && <p className="text-body-l text-text-secondary">{article.standfirst}</p>}
              <p className="text-caption text-text-secondary">
                {article.authors.map((a) => a.name).join(", ")} ·{" "}
                {t("minutes", { n: article.reading_minutes })}
              </p>
              {article.image && (
                <Picture
                  image={article.image}
                  mediaBase={data?.media_base_url ?? ""}
                  sizes="720px"
                  className="h-auto w-full rounded-md"
                />
              )}
              {article.update_note && <p className="text-caption">{article.update_note}</p>}
              <ArticleBody document={article.body} context={context} />
              {article.correction_note && (
                <p className="rounded-md bg-surface-sunken p-4 text-caption">{article.correction_note}</p>
              )}
            </article>
          ) : (
            <ArticleBody.Skeleton />
          )}
        </div>
      )}
    </Dialog>
  );
}
