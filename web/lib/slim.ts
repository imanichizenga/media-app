/**
 * A document without the framework's client: what it would hydrate is done by web/islands in a few kilobytes, and the
 * page's data is not sent twice. A script stays only if it says so (data-keep) and is a file of ours (src): nothing
 * inline ever runs (lib/csp.ts). JSON-LD is data, not script, and stays.
 */
const SCRIPT = /<script\b([^>]*)>([\s\S]*?)<\/script>/g;

export function slim(page: string): { html: string; status?: number } {
  const html = page
    .replace(SCRIPT, (whole, attrs: string, body: string) => {
      if (/\btype="application\/ld\+json"/.test(attrs)) return whole;
      if (/\bdata-keep\b/.test(attrs) && /\bsrc="\/js\//.test(attrs) && !body.trim()) return whole;
      return "";
    })
    .replace(/<link\b(?=[^>]*\bas="script")[^>]*>/g, "");
  const status = /<meta name="x-status" content="(\d{3})"\/?>/.exec(html)?.[1];
  return { html, ...(status ? { status: Number(status) } : {}) };
}

/** Scripts that would run inline in a document: none, ever (a test and the e2e suite hold every page to it). */
export function inlineScripts(html: string): string[] {
  return [...html.matchAll(SCRIPT)]
    .filter(([, attrs = "", body = ""]) => {
      if (/\btype="application\/ld\+json"/.test(attrs)) return false;
      return body.trim() !== "" || !/\bsrc=/.test(attrs);
    })
    .map(([whole]) => whole.slice(0, 120));
}
