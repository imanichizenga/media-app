import "server-only";
import { createPublicClient, type Schemas } from "@news/api-client/public";
import { cache } from "react";
import { env } from "./env";
import type { Locale } from "./locale";
import type { Asked } from "./search";

export type Card = Schemas["Card"];
export type Article = Schemas["Article"];
export type Home = Schemas["Home"];
export type Site = Schemas["SiteConfig"];
export type Nav = Schemas["NavigationItem"];
export type Found = Schemas["Search"];
export type Hit = Schemas["SearchHit"];

export class Gone extends Error {}
export class Unavailable extends Error {}

/**
 * The data cache: every answer is kept, tagged, and made again when the newsroom says so (`/api/revalidate`) or after
 * a while. Pages are rendered from it for each request, and each is cheap to make again (ADR-0046).
 */
async function read<R>(
  ask: (options: { next: { revalidate: number; tags: string[] } }) => Promise<{
    data?: R;
    response: Response;
  }>,
  seconds: number,
  tags: string[],
): Promise<R> {
  let result: { data?: R; response: Response };
  try {
    result = await ask({ next: { revalidate: seconds, tags } });
  } catch (error) {
    throw new Unavailable(String(error));
  }
  if (result.response.status === 404 || result.response.status === 400) throw new Gone();
  if (!result.response.ok || result.data === undefined) throw new Unavailable(String(result.response.status));
  return result.data;
}
const client = () => createPublicClient({ baseUrl: env.api });
export const pathTag = (path: string) => `path:${path}`;

export const site = cache(() => read((o) => client().GET("/api/v1/site-config", o), 300, ["site", "brand"]));
export const navigation = cache((locale: Locale) =>
  read((o) => client().GET("/api/v1/content/navigation", { params: { query: { locale } }, ...o }), 3600, [
    "navigation",
  ]),
);
export const pages = cache((locale: Locale) =>
  read((o) => client().GET("/api/v1/content/pages", { params: { query: { locale } }, ...o }), 3600, [
    "pages",
  ]),
);
export const page = cache((locale: Locale, key: string) =>
  read(
    (o) =>
      client().GET("/api/v1/content/pages/{key}", { params: { path: { key }, query: { locale } }, ...o }),
    3600,
    ["pages", `page-${key}`],
  ),
);
export const home = cache((locale: Locale) =>
  read((o) => client().GET("/api/v1/content/home", { params: { query: { locale } }, ...o }), 60, ["latest"]),
);
export const article = cache((locale: Locale, slug: string, path: string) =>
  read(
    (o) =>
      client().GET("/api/v1/content/articles/{slug}", {
        params: { path: { slug }, query: { locale } },
        ...o,
      }),
    300,
    [pathTag(path), "latest-articles"],
  ),
);
export const related = cache((locale: Locale, slug: string) =>
  read(
    (o) =>
      client().GET("/api/v1/content/articles/{slug}/related", {
        params: { path: { slug }, query: { locale } },
        ...o,
      }),
    600,
    ["latest"],
  ),
);
type Paging = { cursor?: string; limit?: number };
export const latest = cache((locale: Locale, p: Paging = {}) =>
  read((o) => client().GET("/api/v1/content/latest", { params: { query: { locale, ...p } }, ...o }), 60, [
    "latest",
  ]),
);
export const byType = cache((locale: Locale, kind: string, p: Paging = {}) =>
  read(
    (o) =>
      client().GET("/api/v1/content/types/{kind}", {
        params: { path: { kind: kind as "video" }, query: { locale, ...p } },
        ...o,
      }),
    120,
    ["latest"],
  ),
);
export const category = cache((locale: Locale, slug: string, p: Paging = {}) =>
  read(
    (o) =>
      client().GET("/api/v1/content/categories/{slug}", {
        params: { path: { slug }, query: { locale, ...p } },
        ...o,
      }),
    120,
    ["latest", "navigation"],
  ),
);
export const tag = cache((locale: Locale, slug: string, p: Paging = {}) =>
  read(
    (o) =>
      client().GET("/api/v1/content/tags/{slug}", {
        params: { path: { slug }, query: { locale, ...p } },
        ...o,
      }),
    300,
    ["latest", `tag-${slug}`],
  ),
);
export const story = cache((locale: Locale, slug: string, p: Paging = {}) =>
  read(
    (o) =>
      client().GET("/api/v1/content/stories/{slug}", {
        params: { path: { slug }, query: { locale, ...p } },
        ...o,
      }),
    300,
    ["latest", `story-${slug}`],
  ),
);
export const author = cache((locale: Locale, slug: string, p: Paging = {}) =>
  read(
    (o) =>
      client().GET("/api/v1/content/authors/{slug}", {
        params: { path: { slug }, query: { locale, ...p } },
        ...o,
      }),
    300,
    ["latest"],
  ),
);
/**
 * What a reader asked for, already checked (lib/search.ts), as its query string: `cache` knows a string again, not
 * an object, so the page and its metadata share one answer. The same question is one answer for a minute.
 */
export const search = cache((locale: Locale, asked: string) =>
  read(
    (o) =>
      client().GET("/api/v1/content/search", {
        params: { query: { locale, ...(Object.fromEntries(new URLSearchParams(asked)) as Asked) } },
        ...o,
      }),
    60,
    ["search", "latest"],
  ),
);
/** Which ways of signing in are open (ADR-0050): the same for everyone, kept a minute; a failure offers none. */
export const authMethods = cache(async () => {
  try {
    return await read((o) => client().GET("/api/v1/auth/methods", o), 60, ["auth"]);
  } catch {
    return {
      phone: false,
      google: false,
      apple: false,
      local_sms: false,
      resend_seconds: 60,
      terms_version: "",
    };
  }
});
export const sitemapIndex = () => read((o) => client().GET("/api/v1/content/sitemap", o), 300, ["latest"]);
export const sitemapNews = () => read((o) => client().GET("/api/v1/content/sitemap/news", o), 60, ["latest"]);
export const sitemapMonth = (month: string) =>
  read((o) => client().GET("/api/v1/content/sitemap/{month}", { params: { path: { month } }, ...o }), 300, [
    "latest",
  ]);
/** Where an old address lives now, or null. */
export async function moved(path: string): Promise<string | null> {
  try {
    const found = await read(
      (o) => client().GET("/api/v1/content/resolve", { params: { query: { path } }, ...o }),
      60,
      ["redirects", pathTag(path)],
    );
    return found.path === path ? null : found.path;
  } catch {
    return null;
  }
}
/** Nothing found is null; anything else that goes wrong is an error page. */
export async function orNull<R>(promise: Promise<R>): Promise<R | null> {
  try {
    return await promise;
  } catch (error) {
    if (error instanceof Gone) return null;
    throw error;
  }
}
