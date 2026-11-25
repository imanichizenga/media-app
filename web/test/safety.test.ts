import { describe, expect, test } from "vitest";
import { policy } from "@/lib/csp";
import { internalToken } from "@/lib/internal";
import { messageOf, sign, verify } from "@/lib/signature";
import { slim } from "@/lib/slim";
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
  const csp = policy("abc", { media: "https://media.example/x" });
  test("lets nothing run that is not ours", () => {
    expect(csp).toContain("default-src 'none'");
    expect(csp).toContain("script-src 'self' 'nonce-abc' 'strict-dynamic'");
    expect(csp.match(/script-src[^;]*/)?.[0]).not.toContain("unsafe");
    expect(csp).toContain("frame-ancestors 'none'");
    expect(csp).toContain("upgrade-insecure-requests");
  });
  test("names the media host, and only a real one", () => {
    expect(csp).toContain("img-src 'self' data: https://media.example https://i.ytimg.com");
    expect(policy("a", { media: "javascript:alert(1)" })).not.toContain("javascript");
  });
});

describe("a document", () => {
  const page =
    '<html><head><link rel="preload" as="script" href="/_next/a.js"/><link rel="stylesheet" href="/a.css"/><script src="/_next/a.js" async=""></script><script nonce="n" data-keep="">early</script><script type="module" src="/js/s.js" nonce="n" data-keep=""></script></head><body><script type="application/ld+json">{"a":1}</script><script nonce="n">self.__next_f.push([1,"<b>"])</script>hi</body></html>';
  test("keeps its own scripts and data, and nothing of the framework's", () => {
    const { html } = slim(page);
    expect(html).not.toContain("/_next/a.js");
    expect(html).not.toContain("__next_f");
    expect(html).toContain("early");
    expect(html).toContain("/js/s.js");
    expect(html).toContain('{"a":1}');
    expect(html).toContain('href="/a.css"');
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
    "/author/x",
    "/video",
    "/shorts",
    "/search",
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
    "author",
    "video",
    "shorts",
    "explore",
    null,
    "still",
    null,
  ]);
});
test("XML keeps only what XML may hold", () => expect(x("a\u0000<&\"'")).toBe("a&lt;&amp;&quot;&apos;"));
