import { createHash } from "node:crypto";
import { describe, expect, test } from "vitest";
import { policy } from "@/lib/csp";
import { STYLE } from "@/lib/failure-style";
import { internalToken } from "@/lib/internal";
import { messageOf, sign, verify } from "@/lib/signature";
import { inlineScripts, slim } from "@/lib/slim";
import { violations } from "@/lib/violations";
import { x } from "@/lib/xml";
import { kindOf } from "../islands/navigate";

const secret = "s".repeat(32);
const body = '{"id":"abc","tags":["latest"],"paths":["/siasa/habari"]}';
const now = 1_790_000_000_000;
const stamp = String(now / 1000);
const good = { timestamp: stamp, signature: sign(secret, stamp, body), body };

describe("the revalidation order", () => {
  test("is the API's own signature", () =>
    // From the API: hmac.new(b"s" * 32, b"1790000000.{}", sha256).hexdigest()
    expect(sign(secret, "1790000000", "{}")).toBe(
      "0424597c0cb2bcfe8834c80214b6ad44bffa6b97d9a4782368d8585e6d830d4a",
    ));
  test("is accepted inside five minutes", () => {
    expect(verify(secret, good, now)).toBe(true);
    expect(verify(secret, good, now + 299_000)).toBe(true);
  });
  test.each([
    ["late", good, now + 301_000],
    ["early", good, now - 301_000],
    ["changed", { ...good, body: `${body} ` }, now],
    ["another time", { ...good, timestamp: String(now / 1000 + 1) }, now],
    ["no signature", { ...good, signature: null }, now],
    ["short signature", { ...good, signature: "ab" }, now],
    ["a time that is not one", { ...good, timestamp: "1e9" }, now],
  ])("is refused: %s", (_, order, at) => expect(verify(secret, order, at)).toBe(false));
  test("another secret is refused", () => expect(verify("t".repeat(32), good, now)).toBe(false));
  test("says only what it may", () => {
    expect(messageOf(body)).toEqual({ id: "abc", tags: ["latest"], paths: ["/siasa/habari"] });
    for (const bad of [
      "",
      "[]",
      '{"id":"a"}',
      '{"id":"","tags":[],"paths":[]}',
      '{"id":"a","tags":["a b"],"paths":[]}',
      '{"id":"a","tags":[],"paths":["x"]}',
    ])
      expect(messageOf(bad)).toBeNull();
  });
});

describe("the policy", () => {
  const csp = policy({ media: "https://media.example/x" });
  const directive = (name: string) => csp.split("; ").find((d) => d.startsWith(`${name} `));
  test("lets nothing run that is not a file of ours, and has no nonce to leak", () => {
    expect(csp).toContain("default-src 'none'");
    expect(directive("script-src")).toBe("script-src 'self'");
    expect(csp).not.toMatch(/nonce|strict-dynamic|unsafe-eval|unsafe-hashes/);
    // Only style attributes may be inline (a picture's colour and focal point): they cannot run anything.
    expect(csp.split("; ").filter((d) => d.includes("unsafe-inline"))).toEqual([
      "style-src-attr 'unsafe-inline'",
    ]);
    for (const d of ["object-src 'none'", "base-uri 'none'", "frame-ancestors 'none'", "form-action 'self'"])
      expect(csp).toContain(d);
    expect(csp).toContain("upgrade-insecure-requests");
  });
  test("names the media host and YouTube's privacy host, and only real ones", () => {
    expect(directive("img-src")).toBe("img-src 'self' data: https://media.example https://i.ytimg.com");
    expect(directive("media-src")).toBe("media-src 'self' blob: https://media.example");
    expect(directive("connect-src")).toBe("connect-src 'self' https://media.example");
    expect(directive("frame-src")).toBe("frame-src https://www.youtube-nocookie.com");
    expect(policy({ media: "javascript:alert(1)" })).not.toContain("javascript");
  });
  test("allows the failure page's style by its hash, and nothing else inline", () => {
    const style = directive("style-src") ?? "";
    expect(style).toMatch(/^style-src 'self' 'sha256-[A-Za-z0-9+/]+=*'$/);
    const hash = createHash("sha256").update(STYLE).digest("base64");
    expect(style).toContain(hash);
  });
  test("asks for Trusted Types, with one policy, and says where to report", () => {
    expect(csp).toContain("require-trusted-types-for 'script'");
    expect(directive("trusted-types")).toBe("trusted-types navigate");
    expect(csp).toContain("report-uri /api/csp-report");
    expect(csp).toContain("report-to csp");
  });
});

describe("a report of what the policy refused", () => {
  test("is read in both formats, keeping no query string", () => {
    const old = JSON.stringify({
      "csp-report": {
        "document-uri": "https://site.example/siasa?token=secret",
        "effective-directive": "script-src-elem",
        "blocked-uri": "https://evil.example/x.js?u=1",
        "source-file": "https://site.example/js/site-1.js",
        "line-number": 3,
      },
    });
    const [v] = violations(old);
    expect(v).toEqual({
      page: "https://site.example/siasa",
      directive: "script-src-elem",
      blocked: "https://evil.example/x.js",
      source: "https://site.example/js/site-1.js",
      line: 3,
      disposition: "enforce",
    });
    const modern = JSON.stringify([
      {
        type: "csp-violation",
        body: {
          documentURL: "https://site.example/",
          effectiveDirective: "script-src-elem",
          blockedURL: "inline",
        },
      },
      { type: "deprecation", body: {} },
    ]);
    expect(violations(modern)).toEqual([
      expect.objectContaining({ blocked: "inline", page: "https://site.example/" }),
    ]);
  });
  test("anything else is nothing", () => {
    for (const body of ["", "{", "[]", '{"a":1}', "x".repeat(9000)]) expect(violations(body)).toEqual([]);
  });
});

describe("a document", () => {
  const page =
    '<html><head><link rel="preload" as="script" href="/_next/a.js"/><link rel="stylesheet" href="/a.css"/><script src="/_next/a.js" async=""></script><script data-keep="">early</script><script src="/js/early.js" data-keep=""></script><script type="module" src="/js/s.js" data-keep=""></script></head><body><script type="application/ld+json">{"a":1}</script><script nonce="n">self.__next_f.push([1,"<b>"])</script>hi</body></html>';
  test("keeps its own script files and data, and nothing inline or of the framework's", () => {
    const { html } = slim(page);
    expect(html).not.toContain("/_next/a.js");
    expect(html).not.toContain("__next_f");
    expect(html).not.toContain(">early<");
    expect(html).toContain('src="/js/early.js"');
    expect(html).toContain("/js/s.js");
    expect(html).toContain('{"a":1}');
    expect(html).toContain('href="/a.css"');
    expect(inlineScripts(html)).toEqual([]);
    expect(inlineScripts(page).length).toBe(2);
  });
  test("says its own status", () => {
    expect(slim('<meta name="x-status" content="404"/>').status).toBe(404);
    expect(slim(page).status).toBeUndefined();
  });
  test("is asked for with a word nobody else knows", () => {
    expect(internalToken("a")).not.toBe(internalToken("b"));
    expect(internalToken("a")).not.toContain("a".repeat(5));
  });
});

test("which skeleton an address wears", () => {
  const kinds = [
    "/",
    "/en",
    "/siasa",
    "/en/politics",
    "/latest",
    "/siasa/habari",
    "/tag/x",
    "/story/x",
    "/author/x",
    "/video",
    "/shorts",
    "/search",
    "/search?q=maji&kind=videos",
    "/saved",
    "/privacy",
    "/a/b/c",
  ].map(kindOf);
  expect(kinds).toEqual([
    "home",
    "home",
    "front",
    "front",
    "front",
    "article",
    "list",
    "story",
    "author",
    "video",
    "shorts",
    "explore",
    "results",
    null,
    "still",
    null,
  ]);
});
test("XML keeps only what XML may hold", () => expect(x("a\u0000<&\"'")).toBe("a&lt;&amp;&quot;&apos;"));
