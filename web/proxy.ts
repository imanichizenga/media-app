import { type NextRequest, NextResponse } from "next/server";
import { LONG, PUBLIC } from "./lib/cdn";

const origin = (value: string | undefined) => {
  try {
    const url = new URL(value ?? "");
    return ["https:", "http:"].includes(url.protocol) ? url.origin : "";
  } catch {
    return "";
  }
};
const MEDIA = origin(process.env.MEDIA_ORIGIN);
const allow = (...sources: string[]) => sources.filter(Boolean).join(" ");

export function policy(nonce: string, dev = false): string {
  return [
    "default-src 'none'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${dev ? " 'unsafe-eval'" : ""}`,
    `style-src 'self' ${dev ? "'unsafe-inline'" : `'nonce-${nonce}'`}`,
    // A picture's own colour and focal point are style attributes; they can run nothing.
    "style-src-attr 'unsafe-inline'",
    `img-src ${allow("'self'", "data:", MEDIA, "https://i.ytimg.com")}`,
    `media-src ${allow("'self'", "blob:", MEDIA)}`,
    "font-src 'self'",
    `connect-src ${allow("'self'", MEDIA)}`,
    "frame-src https://www.youtube-nocookie.com",
    "manifest-src 'self'",
    "base-uri 'none'",
    "form-action 'self'",
    "frame-ancestors 'none'",
    ...(dev ? [] : ["upgrade-insecure-requests"]),
  ].join("; ");
}

/** A nonce for each rendering, and the language from the address. The CDN keeps the page with its own policy. */
export function proxy(request: NextRequest) {
  const { pathname, search } = request.nextUrl;
  // One address for one page: Swahili has no prefix, and nothing ends in a slash.
  if (pathname === "/sw" || pathname.startsWith("/sw/"))
    return NextResponse.redirect(new URL((pathname.slice(3) || "/") + search, request.url), 301);
  if (/^\/[a-f0-9]{32}\.txt$/.test(pathname))
    return NextResponse.rewrite(new URL(`/indexnow?key=${pathname.slice(1, 33)}`, request.url));
  const locale = pathname === "/en" || pathname.startsWith("/en/") ? "en" : "sw";
  const inner = locale === "en" ? pathname : `/sw${pathname === "/" ? "" : pathname}`;
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
  const csp = policy(nonce, process.env.NODE_ENV === "development").replace(
    process.env.WEB_LOCAL ? "; upgrade-insecure-requests" : "\u0000",
    "",
  );
  const headers = new Headers(request.headers);
  headers.set("x-nonce", nonce);
  headers.set("x-path", pathname);
  headers.set("content-security-policy", csp);
  const response = NextResponse.rewrite(new URL(inner + search, request.url), { request: { headers } });
  response.headers.set("content-security-policy", csp);
  // Only the first page of a list is worth keeping for everyone; the rest is kept too, under its own address.
  const still = /^(\/en)?\/(about|editorial-policy|corrections|contact|privacy|terms)$/.test(pathname);
  response.headers.set("cache-control", still ? LONG : PUBLIC);
  return response;
}

export const config = {
  // Pages only. Everything with a dot (sitemap.xml, robots.txt) and every machine address has its own route.
  matcher: [
    "/((?!api/|_next/|theme/|media/|sitemaps/|rss|og/|healthz|monitoring|indexnow|\\.well-known/|[^/]*\\.(?:xml|ico|webmanifest|png|svg)$|robots\\.txt$).*)",
  ],
};
