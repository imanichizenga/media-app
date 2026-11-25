import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { ImageResponse } from "next/og";
import { article, orNull, site as readSite, type Site } from "@/lib/api";
import { isLocale } from "@/lib/locale";
import { crops, mediaUrl } from "@/lib/seo";

export const dynamic = "force-dynamic";
const SIZE = { width: 1200, height: 630 };
const file = (name: string) => readFile(join(process.cwd(), "fonts", name));
let fonts: Promise<[Buffer, Buffer]> | null = null;
const load = () => {
  fonts ??= Promise.all([file("newsreader-600.woff"), file("inter-500.woff")]);
  return fonts;
};

/** Our own files only, small and quickly, or none: the picture is worth less than the answer. */
async function inline(url: string | undefined, site: Site): Promise<string | null> {
  if (!url?.startsWith(mediaUrl(site, "x").slice(0, -1))) return null;
  const local = process.env.API_PROXY_TARGET;
  const from = !site.media_base_url && local ? `${local}${new URL(url).pathname}` : url;
  try {
    const res = await fetch(from, {
      cache: "no-store",
      redirect: "error",
      signal: AbortSignal.timeout(4000),
    });
    const type = res.headers.get("content-type") ?? "";
    if (!res.ok || !/^image\/(jpeg|png)$/.test(type)) return null;
    const bytes = Buffer.from(await res.arrayBuffer());
    return bytes.length > 4_000_000 ? null : `data:${type};base64,${bytes.toString("base64")}`;
  } catch {
    return null;
  }
}
const shorten = (text: string, most: number) =>
  text.length > most ? `${text.slice(0, most - 1).trimEnd()}…` : text;

/** What is shown when a page is shared: the picture, the words, the name, in the published theme (ADR-0046). */
export async function GET(_: Request, { params }: { params: Promise<{ locale: string; name: string }> }) {
  const { locale, name } = await params;
  const slug = /^([a-z0-9-]{1,120})\.png$/.exec(name)?.[1];
  if (!slug || !isLocale(locale)) return new Response("Not found", { status: 404 });
  const site = await readSite();
  const a = slug === "site" ? null : await orNull(article(locale, slug, `og:${slug}`));
  if (slug !== "site" && !a) return new Response("Not found", { status: 404 });
  const token = (key: string) => site.theme.tokens.light[key] ?? "#111213";
  const { brand_name, tagline_sw, tagline_en, wordmark_light, wordmark_dark } = site.identity;
  const darkMast = token("masthead-fg").toLowerCase() === "#ffffff";
  const logo = darkMast ? (wordmark_dark ?? wordmark_light) : wordmark_light;
  const address = logo?.png["2x"] ?? logo?.png["1x"];
  const [[serif, sans], picture, mark] = await Promise.all([
    load(),
    a && !a.is_sensitive ? inline(crops(site, a.image)[0], site) : null,
    inline(address ? mediaUrl(site, address) : undefined, site),
  ]);
  const headline = shorten(a?.headline ?? brand_name, 120);
  const size = headline.length > 80 ? 52 : headline.length > 50 ? 60 : 68;
  const words = picture ? "#ffffff" : token("masthead-fg");
  return new ImageResponse(
    <div
      style={{
        ...SIZE,
        display: "flex",
        flexDirection: "column",
        background: token("masthead-bg"),
        fontFamily: "Inter",
        position: "relative",
      }}
    >
      {picture && (
        <img
          src={picture}
          alt=""
          width={1200}
          height={630}
          style={{ position: "absolute", objectFit: "cover" }}
        />
      )}
      {picture && (
        <div
          style={{
            position: "absolute",
            ...SIZE,
            background:
              "linear-gradient(180deg, rgba(0,0,0,0.1) 0%, rgba(0,0,0,0.35) 40%, rgba(0,0,0,0.9) 100%)",
          }}
        />
      )}
      <div
        style={{
          display: "flex",
          alignItems: "center",
          height: 96,
          padding: "0 56px",
          background: token("masthead-bg"),
          borderBottom: `6px solid ${token("masthead-rule")}`,
        }}
      >
        {mark && logo ? (
          <img src={mark} alt="" height={48} width={Math.round((48 * logo.width) / logo.height)} />
        ) : (
          <span style={{ fontFamily: "Newsreader", fontSize: 44, color: token("wordmark") }}>
            {brand_name}
          </span>
        )}
      </div>
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          flex: 1,
          justifyContent: picture ? "flex-end" : "center",
          padding: "40px 56px",
        }}
      >
        {a && <span style={{ fontSize: 28, color: words, marginBottom: 12 }}>{a.category.name}</span>}
        <span style={{ fontFamily: "Newsreader", fontSize: size, lineHeight: 1.12, color: words }}>
          {headline}
        </span>
        {!a && (
          <span style={{ fontSize: 32, marginTop: 16, color: words }}>
            {(locale === "en" ? tagline_en : tagline_sw) ?? ""}
          </span>
        )}
      </div>
    </div>,
    {
      ...SIZE,
      fonts: [
        { name: "Newsreader", data: serif, weight: 600 },
        { name: "Inter", data: sans, weight: 500 },
      ],
      // The address changes with the story and with the theme.
      headers: { "cache-control": "public, max-age=86400, s-maxage=31536000, stale-while-revalidate=86400" },
    },
  );
}
