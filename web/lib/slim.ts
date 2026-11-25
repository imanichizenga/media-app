/**
 * A document without the framework's client: what it would hydrate is done by web/islands in a few kilobytes, and the
 * page's data is not sent twice. Scripts that stay say so (data-keep), and data (JSON-LD) is not script.
 */
export function slim(page: string): { html: string; status?: number } {
  const html = page
    .replace(
      /<script\b(?![^>]*\bdata-keep\b)(?![^>]*\btype="application\/ld\+json")[^>]*>[\s\S]*?<\/script>/g,
      "",
    )
    .replace(/<link\b(?=[^>]*\bas="script")[^>]*>/g, "");
  const status = /<meta name="x-status" content="(\d{3})"\/?>/.exec(html)?.[1];
  return { html, ...(status ? { status: Number(status) } : {}) };
}
