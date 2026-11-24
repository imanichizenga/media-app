"use client";
import type { Inline } from "@news/content-schema";
import { EditorContent, useEditor } from "@tiptap/react";
import { useEffect, useId } from "react";
import { inlineFromEditor, inlineToEditor } from "@/lib/editor/convert";
import { textExtensions } from "@/lib/editor/extensions";
import { InlineTools } from "./tools";

/** One paragraph of marked text: captions, quotes, cells. Enter makes a line break. */
export function InlineField({
  label,
  value,
  onChange,
  compact = false,
}: {
  label: string;
  value: Inline[];
  onChange: (content: Inline[]) => void;
  compact?: boolean;
}) {
  const id = useId();
  const editor = useEditor({
    extensions: textExtensions(""),
    injectCSS: false,
    immediatelyRender: false,
    content: { type: "doc", content: [{ type: "paragraph", content: inlineToEditor(value) }] },
    editorProps: {
      attributes: {
        role: "textbox",
        "aria-multiline": "true",
        "aria-labelledby": id,
        class: "editor-inline",
      },
      handleKeyDown: (view, event) => {
        if (event.key !== "Enter" || event.ctrlKey || event.metaKey) return false;
        const type = view.state.schema.nodes.hardBreak;
        if (type) view.dispatch(view.state.tr.replaceSelectionWith(type.create()).scrollIntoView());
        return true;
      },
    },
    onUpdate: ({ editor }) =>
      onChange(
        (editor.getJSON().content ?? []).flatMap((node, i) => [
          ...(i ? [{ type: "hard_break" } as const] : []),
          ...inlineFromEditor(node.content),
        ]),
      ),
  });
  useEffect(() => () => editor?.destroy(), [editor]);
  return (
    <div className="flex flex-col gap-1">
      <span id={id} className={compact ? "sr-only" : "text-label"}>
        {label}
      </span>
      <div className="rounded-sm border border-border-strong bg-surface focus-within:outline-2 focus-within:outline-focus">
        {!compact && editor && <InlineTools editor={editor} />}
        <EditorContent editor={editor} />
      </div>
    </div>
  );
}
