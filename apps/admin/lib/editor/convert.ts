import type { Block, ContentDocument, Inline, Mark } from "@news/content-schema";
import type { JSONContent } from "@tiptap/core";

/** Written directly in the text. Everything else is a `newsBlock`: one card with its own form. */
const ALPHABET = "abcdefghijklmnopqrstuvwxyz0123456789";
export function newId(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(10));
  return `b${Array.from(bytes, (b) => ALPHABET[b % ALPHABET.length]).join("")}`;
}

// ---- document → editor ----
const toMark = (mark: Mark) =>
  mark.type === "link" ? { type: "link", attrs: { href: mark.href } } : { type: mark.type };

export const inlineToEditor = (content: Inline[]): JSONContent[] =>
  content.map((node) =>
    node.type === "hard_break"
      ? { type: "hardBreak" }
      : { type: "text", text: node.text, ...(node.marks?.length ? { marks: node.marks.map(toMark) } : {}) },
  );

function blockToEditor(block: Block): JSONContent {
  switch (block.type) {
    case "paragraph":
      return { type: "paragraph", attrs: { id: block.id }, content: inlineToEditor(block.content) };
    case "heading":
      return {
        type: "heading",
        attrs: { id: block.id, level: block.level },
        content: inlineToEditor(block.content),
      };
    case "list":
      return {
        type: block.ordered ? "orderedList" : "bulletList",
        attrs: { id: block.id },
        content: block.items.map((item) => ({
          type: "listItem",
          content: [{ type: "paragraph", content: inlineToEditor(item.content) }],
        })),
      };
    default:
      return { type: "newsBlock", attrs: { id: block.id, block } };
  }
}

export function toEditor(document: ContentDocument): JSONContent {
  const content = document.blocks.map(blockToEditor);
  return { type: "doc", content: content.length ? content : [{ type: "paragraph" }] };
}

// ---- editor → document ----
const MARKS = new Set(["bold", "italic", "underline", "strike", "code", "superscript", "subscript"]);
function fromMark(mark: { type: string; attrs?: Record<string, unknown> }): Mark | null {
  if (mark.type === "link") return { type: "link", href: String(mark.attrs?.href ?? "") };
  return MARKS.has(mark.type) ? ({ type: mark.type } as Mark) : null;
}

export function inlineFromEditor(content: JSONContent[] = []): Inline[] {
  return content.flatMap((node): Inline[] => {
    if (node.type === "hardBreak") return [{ type: "hard_break" }];
    if (node.type !== "text" || !node.text) return [];
    const marks = (node.marks ?? []).map(fromMark).filter((m): m is Mark => m !== null);
    return [{ type: "text", text: node.text, ...(marks.length ? { marks } : {}) }];
  });
}

export function fromEditor(doc: JSONContent): ContentDocument {
  const blocks = (doc.content ?? []).flatMap((node): Block[] => {
    const id = String(node.attrs?.id || newId());
    switch (node.type) {
      case "paragraph": {
        const content = inlineFromEditor(node.content);
        return content.length ? [{ type: "paragraph", id, content }] : [];
      }
      case "heading": {
        const content = inlineFromEditor(node.content);
        return content.length
          ? [{ type: "heading", id, level: Number(node.attrs?.level ?? 2), content }]
          : [];
      }
      case "bulletList":
      case "orderedList": {
        const items = (node.content ?? [])
          .map((item) => ({ content: inlineFromEditor(item.content?.[0]?.content) }))
          .filter((item) => item.content.length);
        return items.length ? [{ type: "list", id, ordered: node.type === "orderedList", items }] : [];
      }
      case "newsBlock":
        return node.attrs?.block ? [{ ...(node.attrs.block as Block), id }] : [];
      default:
        return [];
    }
  });
  return { version: 1, blocks };
}
