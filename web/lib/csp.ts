const originOf = (value: string | undefined) => {
  try {
    const url = new URL(value ?? "");
    return ["https:", "http:"].includes(url.protocol) ? url.origin : "";
  } catch {
    return "";
  }
};
const allow = (...sources: string[]) => sources.filter(Boolean).join(" ");

export function policy(
  nonce: string,
  { media, dev = false, local = false }: { media?: string; dev?: boolean; local?: boolean } = {},
): string {
  const files = originOf(media);
  return [
    "default-src 'none'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${dev ? " 'unsafe-eval'" : ""}`,
    `style-src 'self' ${dev ? "'unsafe-inline'" : `'nonce-${nonce}'`}`,
    // A picture's own colour and focal point are style attributes; they can run nothing.
    "style-src-attr 'unsafe-inline'",
    `img-src ${allow("'self'", "data:", files, "https://i.ytimg.com")}`,
    `media-src ${allow("'self'", "blob:", files)}`,
    "font-src 'self'",
    `connect-src ${allow("'self'", files)}`,
    "frame-src https://www.youtube-nocookie.com",
    "manifest-src 'self'",
    "base-uri 'none'",
    "form-action 'self'",
    "frame-ancestors 'none'",
    ...(dev || local ? [] : ["upgrade-insecure-requests"]),
  ].join("; ");
}
