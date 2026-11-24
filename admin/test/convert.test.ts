import { readdirSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { type ContentDocument, validateDocument } from "@news/content-schema";
import { getSchema } from "@tiptap/core";
import { describe, expect, it } from "vitest";
import { fromEditor, inlineFromEditor, newId, toEditor } from "../lib/editor/convert";
import { BlockIds, isHref, NewsBlock, textExtensions } from "../lib/editor/extensions";

const dir = resolve(import.meta.dirname, "../../support/docs/content-fixtures/valid");
const fixtures = readdirSync(dir).map(
  (f) => [f, JSON.parse(readFileSync(`${dir}/${f}`, "utf8")) as ContentDocument] as const,
);
const schema = getSchema([...textExtensions(""), BlockIds, NewsBlock]);

/** Marks are a set; neighbours with the same marks are one run. */
const normal = (value: unknown): unknown => {
  if (Array.isArray(value)) {
    const out: Record<string, unknown>[] = [];
    for (const raw of value.map(normal)) {
      const item = raw as Record<string, unknown>;
      const last = out.at(-1);
      const key = (m: unknown) => JSON.stringify(m ?? []);
      if (last?.type === "text" && item?.type === "text" && key(last.marks) === key(item.marks))
        last.text = `${last.text}${item.text}`;
      else out.push(item);
    }
    return out;
  }
  if (value && typeof value === "object")
    return Object.fromEntries(
      Object.entries(value)
        .map(([k, v]) => [
          k,
          k === "marks"
            ? [...(v as object[])].sort((a, b) => JSON.stringify(a).localeCompare(JSON.stringify(b)))
            : normal(v),
        ])
        .filter(([, v]) => !(Array.isArray(v) && v.length === 0 && v === undefined)),
    );
  return value;
};

describe("the editor keeps every fixture exactly", () => {
  it.each(fixtures)("%s", (_, document) => {
    // Through the real schema: what it refuses, a journalist would lose.
    const node = schema.nodeFromJSON(toEditor(document));
    node.check();
    const back = fromEditor(node.toJSON());
    expect(normal(back)).toEqual(normal(document));
    expect(validateDocument(back).ok).toBe(true);
  });
});

describe("what the editor sends", () => {
  it("drops empty paragraphs and headings", () =>
    expect(
      fromEditor({ type: "doc", content: [{ type: "paragraph" }, { type: "heading", attrs: { level: 2 } }] }),
    ).toEqual({ version: 1, blocks: [] }));
  it("ignores nodes and marks it does not know", () =>
    expect(
      inlineFromEditor([{ type: "text", text: "a", marks: [{ type: "highlight" }] }, { type: "image" }]),
    ).toEqual([{ type: "text", text: "a" }]));
  it("makes ids the schema accepts", () => {
    const ids = Array.from({ length: 200 }, newId);
    expect(new Set(ids).size).toBe(200);
    for (const id of ids) expect(id).toMatch(/^[A-Za-z0-9_-]{6,40}$/);
  });
  it.each(["javascript:alert(1)", "data:text/html,x", "//evil.example", "/\\evil", " https://x", "ftp://x"])(
    "refuses the link %s",
    (href) => expect(isHref(href)).toBe(false),
  );
  it.each(["https://example.org/a", "mailto:a@example.org", "/habari/kichwa"])(
    "accepts the link %s",
    (href) => expect(isHref(href)).toBe(true),
  );
});
