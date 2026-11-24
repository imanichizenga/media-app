import { type Inline, type ListItem, type ReadBlock, readDocument } from "@news/content-schema";
import type { ReactNode } from "react";
import { type Asset, type ImageAsset, imageUrl, Picture, type VideoAsset } from "./media";
import { VideoPlayer, YouTubeFacade } from "./player";

export type ContentLabels = {
  play: string;
  playError: string;
  sensitive: string;
  readAlso: string;
  openPost: string;
  unsupported: string;
  pinned: string;
  gallery: string;
};
export type ContentContext = {
  assets: Record<string, Asset>;
  links: Record<string, { path: string; headline: string }>;
  mediaBase: string;
  labels: ContentLabels;
  /** Third parties may be loaded on request. Off in the admin, whose policy allows none. */
  interactive: boolean;
  formatTime: (iso: string) => string;
};

const TAGS = {
  bold: "strong",
  italic: "em",
  underline: "u",
  strike: "s",
  code: "code",
  superscript: "sup",
  subscript: "sub",
} as const;
const external = (href: string) => /^https?:/.test(href);

export function InlineContent({ content }: { content: Inline[] }) {
  return content.map((node, i): ReactNode => {
    if (node.type === "hard_break")
      // biome-ignore lint/suspicious/noArrayIndexKey: text never reorders
      return <br key={i} />;
    return (node.marks ?? []).reduceRight<ReactNode>(
      (inner, mark) => {
        if (mark.type !== "link") {
          const Tag = TAGS[mark.type];
          return Tag ? (
            <Tag
              // biome-ignore lint/suspicious/noArrayIndexKey: text never reorders
              key={i}
              className={
                mark.type === "code" ? "rounded-sm bg-surface-sunken px-1 font-mono text-[0.9em]" : ""
              }
            >
              {inner}
            </Tag>
          ) : (
            inner
          );
        }
        return (
          <a
            // biome-ignore lint/suspicious/noArrayIndexKey: text never reorders
            key={i}
            href={mark.href}
            className="text-link underline decoration-1 underline-offset-2"
            {...(external(mark.href) ? { rel: "noopener" } : {})}
          >
            {inner}
          </a>
        );
      },
      // biome-ignore lint/suspicious/noArrayIndexKey: text never reorders
      <span key={i}>{node.text}</span>,
    );
  });
}

function Figure({
  caption,
  credit,
  children,
  className = "",
}: {
  caption?: Inline[];
  credit?: string;
  children: ReactNode;
  className?: string;
}) {
  return (
    <figure className={className}>
      {children}
      {(Boolean(caption?.length) || credit) && (
        <figcaption className="pt-2 text-caption text-text-secondary">
          {caption && <InlineContent content={caption} />}
          {credit && <span className="text-text-tertiary"> {credit}</span>}
        </figcaption>
      )}
    </figure>
  );
}

/** Covered until the reader chooses to look. Works without script. */
function Covered({ on, label, children }: { on?: boolean; label: string; children: ReactNode }) {
  if (!on) return children;
  return (
    <details className="group relative overflow-hidden rounded-md bg-surface-sunken">
      <summary className="tap flex cursor-pointer items-center justify-center p-8 text-label text-text-secondary group-open:p-2">
        {label}
      </summary>
      {children}
    </details>
  );
}

const Missing = ({ label }: { label: string }) => (
  <p className="rounded-md border border-border border-dashed p-4 text-caption text-text-secondary">
    {label}
  </p>
);

function ImageFigure({
  asset,
  alt,
  caption,
  credit,
  sizes,
  context,
}: {
  asset: Asset | undefined;
  alt: string;
  caption?: Inline[];
  credit?: string;
  sizes: string;
  context: ContentContext;
}) {
  if (asset?.kind !== "image") return <Missing label={alt || context.labels.unsupported} />;
  return (
    <Figure caption={caption} credit={credit || asset.credit}>
      <Picture
        image={asset as ImageAsset}
        mediaBase={context.mediaBase}
        alt={alt}
        sizes={sizes}
        className="h-auto w-full rounded-md"
      />
    </Figure>
  );
}

const Items = ({ items, ordered }: { items: ListItem[]; ordered: boolean }) => {
  const Tag = ordered ? "ol" : "ul";
  return (
    <Tag className={`flex flex-col gap-2 pl-6 ${ordered ? "list-decimal" : "list-disc"}`}>
      {items.map((item, i) => (
        // biome-ignore lint/suspicious/noArrayIndexKey: lists never reorder
        <li key={i}>
          <InlineContent content={item.content} />
        </li>
      ))}
    </Tag>
  );
};

const PROVIDERS = { x: "X", instagram: "Instagram", facebook: "Facebook", tiktok: "TikTok" };
const TONES = {
  info: "border-border-strong bg-surface-sunken",
  warning: "border-warning bg-warning-soft",
  success: "border-success bg-success-soft",
};
const WIDE = "(min-width: 1024px) 720px, 100vw";

export function BlockView({ block, context }: { block: ReadBlock; context: ContentContext }): ReactNode {
  const { assets, labels, mediaBase } = context;
  switch (block.type) {
    case "paragraph":
      return (
        <p>
          <InlineContent content={block.content} />
        </p>
      );
    case "heading": {
      const Tag = `h${Math.min(Math.max(block.level, 2), 4)}` as "h2" | "h3" | "h4";
      const size = { h2: "text-headline-m", h3: "text-headline-s", h4: "text-title" }[Tag];
      return (
        <Tag className={`font-serif ${size} pt-4`}>
          <InlineContent content={block.content} />
        </Tag>
      );
    }
    case "list":
      return <Items items={block.items} ordered={block.ordered} />;
    case "image":
      return (
        <Covered on={block.sensitive} label={labels.sensitive}>
          <ImageFigure {...block} asset={assets[block.asset]} sizes={WIDE} context={context} />
        </Covered>
      );
    case "gallery": {
      const grid = block.layout === "grid";
      return (
        <section
          aria-label={`${labels.gallery} (${block.items.length})`}
          // biome-ignore lint/a11y/noNoninteractiveTabindex: a scrollable region must be reachable by keyboard
          tabIndex={0}
          className={
            grid
              ? "grid grid-cols-2 gap-3 sm:grid-cols-3"
              : "-mx-4 flex snap-x snap-mandatory gap-3 overflow-x-auto px-4"
          }
        >
          {block.items.map((item, i) => (
            <div
              // biome-ignore lint/suspicious/noArrayIndexKey: a picture may appear twice
              key={`${item.asset}-${i}`}
              className={grid ? "" : "w-[85%] shrink-0 snap-center sm:w-[70%]"}
            >
              <ImageFigure
                {...item}
                asset={assets[item.asset]}
                sizes="(min-width: 640px) 500px, 85vw"
                context={context}
              />
            </div>
          ))}
        </section>
      );
    }
    case "video": {
      const asset = assets[block.asset];
      if (asset?.kind !== "video") return <Missing label={labels.unsupported} />;
      return (
        <Covered on={block.sensitive} label={labels.sensitive}>
          <Figure caption={block.caption} credit={block.credit || asset.credit}>
            <VideoPlayer
              video={asset as VideoAsset}
              mediaBase={mediaBase}
              playLabel={labels.play}
              errorLabel={labels.playError}
            />
          </Figure>
        </Covered>
      );
    }
    case "youtube":
      return (
        <YouTubeFacade
          videoId={block.videoId}
          title={block.title ?? ""}
          start={block.start}
          vertical={block.vertical}
          interactive={context.interactive}
          playLabel={labels.play}
        />
      );
    case "quote":
      return (
        <blockquote className="border-border-strong border-l-4 pl-4 text-text-secondary">
          <p>
            <InlineContent content={block.content} />
          </p>
          {block.attribution && <footer className="pt-1 text-label">{block.attribution}</footer>}
        </blockquote>
      );
    case "pull_quote":
      return (
        <blockquote className="border-text-primary border-y py-6 text-center font-serif text-headline-m">
          <p>{block.text}</p>
          {block.attribution && (
            <footer className="pt-2 font-sans text-label text-text-secondary">{block.attribution}</footer>
          )}
        </blockquote>
      );
    case "embed":
      return (
        <blockquote className="rounded-md border border-border p-4">
          {block.text && <p className="whitespace-pre-line">{block.text}</p>}
          <footer className="flex flex-wrap items-center justify-between gap-2 pt-2 text-label text-text-secondary">
            <span>{[block.author, PROVIDERS[block.provider]].filter(Boolean).join(" · ")}</span>
            <a
              href={block.url}
              rel="noopener noreferrer nofollow"
              target="_blank"
              className="tap inline-flex items-center text-link"
            >
              {labels.openPost}
            </a>
          </footer>
        </blockquote>
      );
    case "table": {
      const [first, ...rest] = block.rows;
      const body = block.header ? rest : block.rows;
      return (
        <section
          aria-label={block.caption || undefined}
          // biome-ignore lint/a11y/noNoninteractiveTabindex: a scrollable region must be reachable by keyboard
          tabIndex={0}
          className="overflow-x-auto"
        >
          <table className="w-full border-collapse text-body-m">
            {block.caption && (
              <caption className="pb-2 text-left text-caption text-text-secondary">{block.caption}</caption>
            )}
            {block.header && first && (
              <thead>
                <tr>
                  {first.cells.map((cell, i) => (
                    // biome-ignore lint/suspicious/noArrayIndexKey: cells never reorder
                    <th key={i} scope="col" className="border-border-strong border-b-2 px-3 py-2 text-left">
                      <InlineContent content={cell.content} />
                    </th>
                  ))}
                </tr>
              </thead>
            )}
            <tbody>
              {body.map((row, r) => (
                // biome-ignore lint/suspicious/noArrayIndexKey: rows never reorder
                <tr key={r}>
                  {row.cells.map((cell, i) => (
                    // biome-ignore lint/suspicious/noArrayIndexKey: cells never reorder
                    <td key={i} className="border-border border-b px-3 py-2 align-top">
                      <InlineContent content={cell.content} />
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      );
    }
    case "callout":
      return (
        <aside className={`rounded-md border-l-4 p-4 ${TONES[block.tone]}`}>
          {block.title && <p className="text-title">{block.title}</p>}
          <p>
            <InlineContent content={block.content} />
          </p>
        </aside>
      );
    case "factbox":
      return (
        <aside className="rounded-md border border-border bg-surface-sunken p-5">
          <p className="pb-3 text-title">{block.title}</p>
          <Items items={block.items} ordered={false} />
        </aside>
      );
    case "related_link": {
      const target = block.post ? context.links[block.post]?.path : block.url;
      if (!target) return null; // a withdrawn post leaves no dead end
      return (
        <a href={target} className="block rounded-md border border-border p-4 hover:bg-surface-sunken">
          <span className="block text-caption text-text-secondary">{labels.readAlso}</span>
          <span className="text-title">{block.title}</span>
        </a>
      );
    }
    case "poll":
      // Voting arrives with engagement (M4). Until then the question is readable and nothing looks pressable.
      return (
        <section className="rounded-md border border-border p-5">
          <p className="pb-3 text-title">{block.question}</p>
          <ul className="flex flex-col gap-2">
            {block.options.map((option) => (
              <li key={option.id} className="rounded-sm bg-surface-sunken px-4 py-3">
                {option.label}
              </li>
            ))}
          </ul>
        </section>
      );
    case "live_update":
      return (
        <article id={block.id} className="relative border-border border-l-2 pb-2 pl-5">
          <span aria-hidden className="absolute top-1.5 -left-1.25 size-2 rounded-full bg-text-primary" />
          <p className="flex flex-wrap gap-2 text-label text-text-secondary">
            <time dateTime={block.time}>{context.formatTime(block.time)}</time>
            {block.pinned && <span className="text-text-primary">{labels.pinned}</span>}
          </p>
          {block.title && <h3 className="text-title">{block.title}</h3>}
          <div className="flex flex-col gap-4 pt-2">
            {block.blocks.map((inner) => (
              <BlockView key={inner.id} block={inner} context={context} />
            ))}
          </div>
        </article>
      );
    default:
      return <Missing label={labels.unsupported} />;
  }
}

export function ArticleBody({ document, context }: { document: unknown; context: ContentContext }) {
  return (
    <div className="flex flex-col gap-5 break-words text-body-l">
      {readDocument(document).blocks.map((block) => (
        <BlockView key={block.id} block={block} context={context} />
      ))}
    </div>
  );
}

ArticleBody.Skeleton = function ArticleBodySkeleton() {
  return (
    <div aria-hidden className="flex flex-col gap-5 text-body-l" data-skeleton="article">
      {[4, 3, 5].map((lines) => (
        <p key={lines}>
          {Array.from({ length: lines }, (_, i) => (
            // biome-ignore lint/suspicious/noArrayIndexKey: static placeholders
            <span key={i} className={`bone ${i === lines - 1 ? "w-2/3" : "w-full"}`}>
              {"\u00a0"}
            </span>
          ))}
        </p>
      ))}
    </div>
  );
};

export { imageUrl };
