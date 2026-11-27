/**
 * The search page's question, from its address (ADR-0049). Only what the API knows is passed on, so a strange address
 * is the plain search for its words, never an error page; and the words are bounded as the API bounds them.
 */
export const SINCE = ["24h", "7d", "30d", "1y"] as const;
export const SORTS = ["relevance", "newest"] as const;
/** A reader picks a kind of story; the API is asked for its types. */
export const KINDS = {
  stories: "article,breaking,opinion",
  videos: "video,youtube,short",
  live: "live_blog,live_stream",
  galleries: "gallery",
} as const;
export type Kind = keyof typeof KINDS;
export type Asked = {
  q: string;
  type?: string;
  category?: string;
  since?: (typeof SINCE)[number];
  sort?: (typeof SORTS)[number];
  cursor?: string;
};
export type Wanted = {
  q: string;
  kind?: Kind;
  since?: Asked["since"];
  sort?: Asked["sort"];
  cursor?: string;
};
type Raw = Record<string, string | string[] | undefined>;

const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v) ?? "";
const among = <V extends string>(list: readonly V[], v: string): V | undefined =>
  (list as readonly string[]).includes(v) ? (v as V) : undefined;

/** Lower case is the API's business; here, spaces collapse and the words stop at 100 letters. */
export const tidy = (q: string) => q.replace(/\s+/g, " ").trim().slice(0, 100).trim();

export function wantedOf(raw: Raw): Wanted {
  const kind = one(raw.kind);
  const cursor = one(raw.cursor);
  return {
    q: tidy(one(raw.q)),
    kind: kind in KINDS ? (kind as Kind) : undefined,
    since: among(SINCE, one(raw.since)),
    sort: among(SORTS, one(raw.sort)) === "newest" ? "newest" : undefined,
    cursor: /^[A-Za-z0-9_=-]{1,500}$/.test(cursor) ? cursor : undefined,
  };
}
/** For the API: one string, so the same question is the same cache entry. */
export function askedOf(w: Wanted): string {
  const asked: Asked = { q: w.q };
  if (w.kind) asked.type = KINDS[w.kind];
  if (w.since) asked.since = w.since;
  if (w.sort) asked.sort = w.sort;
  if (w.cursor) asked.cursor = w.cursor;
  return new URLSearchParams(asked as Record<string, string>).toString();
}
/** This page's own address for a question: what is not chosen is left out, so one question has one address. */
export function addressOf(base: string, w: Wanted, change: Partial<Wanted> = {}): string {
  const next = { ...w, cursor: undefined, ...change };
  const query = new URLSearchParams();
  if (next.q) query.set("q", next.q);
  if (next.kind) query.set("kind", next.kind);
  if (next.since) query.set("since", next.since);
  if (next.sort) query.set("sort", next.sort);
  if (next.cursor) query.set("cursor", next.cursor);
  const text = query.toString();
  return text ? `${base}?${text}` : base;
}
