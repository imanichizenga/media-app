import { describe, expect, test } from "vitest";
import { addressOf, askedOf, tidy, wantedOf } from "@/lib/search";

describe("the search page's address (ADR-0049)", () => {
  test("only what the API knows is passed on; anything else is the plain search for the words", () => {
    expect(wantedOf({ q: "  chanjo   Mbeya ", kind: "videos", since: "7d", sort: "newest" })).toEqual({
      q: "chanjo Mbeya",
      kind: "videos",
      since: "7d",
      sort: "newest",
      cursor: undefined,
    });
    expect(
      wantedOf({ q: "x", kind: "nonsense", since: "1000y", sort: "random", cursor: "<script>" }),
    ).toEqual({
      q: "x",
      kind: undefined,
      since: undefined,
      sort: undefined,
      cursor: undefined,
    });
    // The order the API sorts by anyway is not written into the address.
    expect(wantedOf({ q: "x", sort: "relevance" }).sort).toBeUndefined();
    expect(wantedOf({ q: ["a", "b"] }).q).toBe("a");
  });

  test("the words stop at 100 letters, as the API's do", () => {
    expect(tidy(`${"a".repeat(99)} b`)).toBe("a".repeat(99));
    expect(tidy("a".repeat(150))).toHaveLength(100);
  });

  test("a reader's kind is the API's types, and one question is one cache entry", () => {
    const asked = new URLSearchParams(askedOf({ q: "maji", kind: "live", since: "24h" }));
    expect(Object.fromEntries(asked)).toEqual({ q: "maji", type: "live_blog,live_stream", since: "24h" });
    expect(askedOf({ q: "maji" })).toBe(askedOf(wantedOf({ q: " maji ", kind: "", sort: "relevance" })));
  });

  test("a filter changes one thing and starts the pages again", () => {
    const now = { q: "maji safi", kind: "stories" as const, cursor: "abc" };
    expect(addressOf("/search", now, { since: "30d" })).toBe("/search?q=maji+safi&kind=stories&since=30d");
    expect(addressOf("/en/search", now, { kind: undefined })).toBe("/en/search?q=maji+safi");
    expect(addressOf("/search", now, { cursor: "next" })).toBe(
      "/search?q=maji+safi&kind=stories&cursor=next",
    );
    expect(addressOf("/search", { q: "" })).toBe("/search");
  });
});
