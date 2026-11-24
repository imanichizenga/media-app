import { readdirSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { BLOCK_TYPES, readDocument, validateDocument } from "../src/index";

const root = resolve(import.meta.dirname, "../../../docs/content-fixtures");
const load = (kind: string) =>
  readdirSync(`${root}/${kind}`).map(
    (name) => [name, JSON.parse(readFileSync(`${root}/${kind}/${name}`, "utf8"))] as const,
  );

describe("valid fixtures", () => {
  it.each(load("valid"))("%s is accepted and read without loss", (_, json) => {
    expect(validateDocument(json)).toEqual({ ok: true, document: json });
    expect(readDocument(json)).toEqual(json);
  });
  it("cover every block type", () => {
    const seen = new Set(load("valid").flatMap(([, d]) => d.blocks.map((b: { type: string }) => b.type)));
    expect([...seen].sort()).toEqual([...BLOCK_TYPES].sort());
  });
});

describe("invalid fixtures", () => {
  it.each(load("invalid"))("%s is refused by the writer and never crashes the reader", (_, json) => {
    expect(validateDocument(json).ok).toBe(false);
    expect(() => readDocument(json)).not.toThrow();
  });
});

describe("a newer server", () => {
  it("adds a block type: the rest of the article still reads", () => {
    const paragraph = { type: "paragraph", id: "block-2", content: [{ type: "text", text: "a" }] };
    expect(
      readDocument({ version: 1, blocks: [{ type: "hologram", id: "block-1" }, paragraph] }).blocks,
    ).toEqual([{ type: "unknown", id: "block-1", originalType: "hologram" }, paragraph]);
  });
  it("adds a field: it is ignored", () => {
    const image = { type: "image", id: "block-1", asset: "0197a000-0000-7000-8000-000000000001", alt: "a" };
    expect(readDocument({ version: 1, blocks: [{ ...image, depth: 3 }] }).blocks).toEqual([image]);
  });
});

it.each([null, undefined, "", 7, [], { blocks: "x" }])("reads %j as an empty article", (input) =>
  expect(readDocument(input).blocks).toEqual([]),
);
