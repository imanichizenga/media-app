import { Extension, Node } from "@tiptap/core";
import Code from "@tiptap/extension-code";
import Subscript from "@tiptap/extension-subscript";
import Superscript from "@tiptap/extension-superscript";
import { Placeholder } from "@tiptap/extensions";
import { Plugin } from "@tiptap/pm/state";
import StarterKit from "@tiptap/starter-kit";
import { newId } from "./convert";

const IDENTIFIED = ["paragraph", "heading", "bulletList", "orderedList", "newsBlock"];
const HREF = /^(https?:\/\/[^\s]+|mailto:[^\s]+|\/([^/\\\s][^\s]*)?)$/;
export const isHref = (href: string) => HREF.test(href) && href.length <= 2048;

/** Top-level blocks keep their id through edits; splitting or pasting gives the copy a new one. */
export const BlockIds = Extension.create({
  name: "blockIds",
  addGlobalAttributes: () => [
    { types: IDENTIFIED, attributes: { id: { default: null, rendered: false, keepOnSplit: false } } },
  ],
  addProseMirrorPlugins: () => [
    new Plugin({
      appendTransaction(transactions, _before, state) {
        if (!transactions.some((t) => t.docChanged)) return null;
        const seen = new Set<string>();
        const { tr } = state;
        state.doc.forEach((node, offset) => {
          if (!IDENTIFIED.includes(node.type.name)) return;
          const { id } = node.attrs;
          if (id && !seen.has(id)) seen.add(id);
          else {
            const fresh = newId();
            seen.add(fresh);
            tr.setNodeAttribute(offset, "id", fresh);
          }
        });
        return tr.steps.length ? tr.setMeta("addToHistory", false) : null;
      },
    }),
  ],
});

export const NewsBlock = Node.create({
  name: "newsBlock",
  group: "block",
  atom: true,
  draggable: true,
  selectable: true,
  // Blocks never travel through HTML: pasted markup cannot become one.
  addAttributes: () => ({ block: { default: null, rendered: false } }),
  parseHTML: () => [],
  renderHTML: () => ["div", { "data-news-block": "" }],
});

export const textExtensions = (placeholder: string) => [
  StarterKit.configure({
    code: false,
    blockquote: false,
    codeBlock: false,
    horizontalRule: false,
    heading: { levels: [2, 3, 4] },
    link: {
      openOnClick: false,
      autolink: false,
      linkOnPaste: false,
      protocols: ["mailto"],
      isAllowedUri: (url) => isHref(url),
    },
    dropcursor: { color: "var(--color-accent)", width: 2 },
  }),
  Code.extend({ excludes: "" }), // code may also be a link, or bold
  Superscript,
  Subscript,
  Placeholder.configure({ placeholder, emptyEditorClass: "is-empty" }),
];
