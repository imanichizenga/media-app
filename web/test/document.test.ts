import { afterEach, describe, expect, test, vi } from "vitest";
import { policy } from "@/lib/csp";
import { inlineScripts } from "@/lib/slim";

// The document route is the layer between Next.js and readers (ADR-0046). If an upgrade of Next changes what it is
// given, these say so: support/docs/runbooks/upgrade-next.md.
process.env.REVALIDATE_SECRET ??= "s".repeat(32);
process.env.SITE_URL ??= "http://localhost:3000";
const { GET } = await import("../app/document/route");
const ask = (path: string) =>
  GET(new Request("http://localhost:3000/document", { headers: { "x-path": path } }));

afterEach(() => vi.unstubAllGlobals());

describe("the document layer", () => {
  test("a page that cannot be made is a designed 503 the CDN does not keep", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new Error("down")));
    const res = await ask("/siasa");
    expect(res.status).toBe(503);
    expect(res.headers.get("cache-control")).toBe("no-store");
    expect(res.headers.get("retry-after")).toBe("30");
    expect(res.headers.get("content-security-policy")).toBe(
      policy({ local: Boolean(process.env.WEB_LOCAL) }),
    );
    const html = await res.text();
    expect(inlineScripts(html)).toEqual([]);
    expect(html).toContain('lang="sw"');
    expect(html).toContain('href="/siasa"');
  });
  test("an error of the page's own is a 503 too, in its language", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(new Response("boom", { status: 500 })));
    const res = await ask("/en/politics");
    expect(res.status).toBe(503);
    expect(await res.text()).toContain('lang="en"');
  });
  test("a permanent move is a 301, a temporary one stays temporary", async () => {
    for (const [given, said] of [
      [308, 301],
      [301, 301],
      [307, 307],
    ]) {
      vi.stubGlobal(
        "fetch",
        vi
          .fn()
          .mockResolvedValue(new Response(null, { status: given, headers: { location: "http://x/y?a=1" } })),
      );
      const res = await ask("/old");
      expect(res.status).toBe(said);
      expect(res.headers.get("location")).toBe("/y?a=1");
    }
  });
  test("the framework's client runtime and its second copy of the data never reach a reader", async () => {
    const framework =
      '<html><head><script src="/_next/static/chunks/main.js" async=""></script><link rel="preload" as="script" href="/_next/x.js"/><script src="/js/early-A.js" data-keep=""></script><script type="module" src="/js/site-B.js" data-keep=""></script></head><body><main>Habari</main><script>self.__next_f=self.__next_f||[]</script><script>self.__next_f.push([1,"0:{}"])</script><script id="__NEXT_DATA__" type="application/json">{}</script></body></html>';
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(new Response(framework, { status: 200 })));
    const html = await (await ask("/")).text();
    expect(html).not.toMatch(/_next\/static|__next_f|__NEXT_DATA__|as="script"/);
    expect([...html.matchAll(/<script[^>]*src="([^"]+)"/g)].map((m) => m[1])).toEqual([
      "/js/early-A.js",
      "/js/site-B.js",
    ]);
    expect(html).toContain("<main>Habari</main>");
  });
});
