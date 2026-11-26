import { type NextRequest, NextResponse } from "next/server";
import { PUBLIC } from "./lib/cdn";
import { policy } from "./lib/csp";
import { env } from "./lib/env";
import { internalToken } from "./lib/internal";

const DEV = process.env.NODE_ENV === "development";

/** The language from the address; and every page as a document (app/document), which asks for the page itself here. */
export function proxy(request: NextRequest) {
  const { pathname, search } = request.nextUrl;
  // One address for one page: Swahili has no prefix.
  if (pathname === "/sw" || pathname.startsWith("/sw/"))
    return NextResponse.redirect(
      new URL((pathname.slice(3).replace(/^\/+/, "/") || "/") + search, env.site),
      { status: 301, headers: { "cache-control": PUBLIC } },
    );
  if (/^\/[a-f0-9]{32}\.txt$/.test(pathname))
    return NextResponse.rewrite(new URL(`/indexnow?key=${pathname.slice(1, 33)}`, request.url));
  const headers = new Headers(request.headers);
  const own = DEV || request.headers.get("x-internal") === internalToken(env.revalidateSecret);
  if (!own) {
    headers.set("x-path", pathname + search);
    return NextResponse.rewrite(new URL("/document", request.url), { request: { headers } });
  }
  const locale = pathname === "/en" || pathname.startsWith("/en/") ? "en" : "sw";
  const inner = locale === "en" ? pathname : `/sw${pathname === "/" ? "" : pathname}`;
  const csp = policy({ media: process.env.MEDIA_ORIGIN, dev: DEV, local: true });
  headers.set("x-locale", locale);
  headers.set("content-security-policy", csp);
  const response = NextResponse.rewrite(new URL(inner + search, request.url), { request: { headers } });
  response.headers.set("content-security-policy", csp);
  return response;
}

export const config = {
  // Pages only. Everything with a dot (sitemap.xml, robots.txt) and every machine address has its own route.
  matcher: [
    "/((?!api/|_next/|js/|theme/|media/|sitemaps/|rss(?:/|$)|feed(?:/|$)|og/|healthz|monitoring|indexnow|\\.well-known/|[^/]*\\.(?:xml|ico|webmanifest|png|svg)$|robots\\.txt$).*)",
  ],
};
