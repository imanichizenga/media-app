import { type NextRequest, NextResponse } from "next/server";

// Where Terraform put the media bucket and its CDN. Origins only, so no path can widen the policy.
const origin = (value: string | undefined) => {
  try {
    const url = new URL(value ?? "");
    return ["https:", "http:"].includes(url.protocol) ? url.origin : "";
  } catch {
    return "";
  }
};
const MEDIA = origin(process.env.MEDIA_ORIGIN);
const UPLOAD = origin(process.env.UPLOAD_ORIGIN);
const allow = (...sources: string[]) => sources.filter(Boolean).join(" ");

/** A fresh nonce per page view: no inline script or style runs without it. */
export function proxy(request: NextRequest) {
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
  const dev = process.env.NODE_ENV === "development";
  const csp = [
    "default-src 'none'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${dev ? " 'unsafe-eval'" : ""}`,
    `style-src 'self' ${dev ? "'unsafe-inline'" : `'nonce-${nonce}'`}`,
    `img-src ${allow("'self'", "data:", MEDIA)}`,
    // The player feeds the video element through a blob address.
    `media-src ${allow("'self'", "blob:", MEDIA)}`,
    "font-src 'self'",
    `connect-src ${allow("'self'", MEDIA, UPLOAD)}`,
    "base-uri 'none'",
    "form-action 'self'",
    "frame-src 'self'",
    `frame-ancestors ${request.nextUrl.pathname === "/preview" ? "'self'" : "'none'"}`,
    "require-trusted-types-for 'script'",
    "trusted-types nextjs nextjs#bundler default ProseMirrorClipboard",
  ]
    .filter((rule) => !dev || !rule.includes("trusted-types"))
    .join("; ");
  const headers = new Headers(request.headers);
  headers.set("x-nonce", nonce);
  headers.set("content-security-policy", csp);
  const response = NextResponse.next({ request: { headers } });
  response.headers.set("content-security-policy", csp);
  response.headers.set("cache-control", "no-store");
  return response;
}

export const config = {
  matcher: [
    "/((?!api|ws/|media/|theme/|preview-media/|monitoring|_next/static|_next/image|favicon.ico|healthz).*)",
  ],
};
