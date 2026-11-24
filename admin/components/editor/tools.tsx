"use client";
import type { Editor } from "@tiptap/core";
import { useEditorState } from "@tiptap/react";
import {
  Bold,
  Code,
  Heading2,
  Heading3,
  Italic,
  Link2,
  List,
  ListOrdered,
  type LucideIcon,
  Redo2,
  Strikethrough,
  Subscript,
  Superscript,
  Underline,
  Undo2,
} from "lucide-react";
import { useTranslations } from "next-intl";
import { type FormEvent, useState } from "react";
import { Button, cx, Dialog, TextField } from "@/components/ui";
import { isHref } from "@/lib/editor/extensions";

const MARKS: [string, LucideIcon][] = [
  ["bold", Bold],
  ["italic", Italic],
  ["underline", Underline],
  ["strike", Strikethrough],
  ["code", Code],
  ["superscript", Superscript],
  ["subscript", Subscript],
];

export function Tool({
  label,
  icon: Icon,
  active,
  disabled,
  onClick,
}: {
  label: string;
  icon: LucideIcon;
  active?: boolean;
  disabled?: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      title={label}
      aria-label={label}
      aria-pressed={active}
      disabled={disabled}
      // Keeps the selection in the text.
      onMouseDown={(e) => e.preventDefault()}
      onClick={onClick}
      className={cx(
        "tap grid w-11 shrink-0 place-items-center rounded-sm disabled:opacity-40",
        active ? "bg-brand-soft text-brand-text" : "text-text-secondary hover:bg-surface-sunken",
      )}
    >
      <Icon aria-hidden size={18} />
    </button>
  );
}

export function InlineTools({ editor }: { editor: Editor }) {
  const t = useTranslations("editor");
  const active = useEditorState({
    editor,
    selector: ({ editor: e }) =>
      Object.fromEntries([...MARKS.map(([m]) => m), "link"].map((m) => [m, e.isActive(m)])),
  });
  return (
    <div role="toolbar" aria-label={t("formatting")} className="flex overflow-x-auto border-border border-b">
      {MARKS.slice(0, 2).map(([mark, icon]) => (
        <Tool
          key={mark}
          label={t(`mark.${mark}` as never)}
          icon={icon}
          active={active?.[mark]}
          onClick={() => editor.chain().focus().toggleMark(mark).run()}
        />
      ))}
      <LinkTool editor={editor} active={active?.link ?? false} />
    </div>
  );
}

function LinkTool({ editor, active }: { editor: Editor; active: boolean }) {
  const t = useTranslations("editor");
  const c = useTranslations("common");
  const [open, setOpen] = useState(false);
  const [bad, setBad] = useState(false);
  const apply = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    e.stopPropagation();
    const raw = String(new FormData(e.currentTarget).get("href")).trim();
    const href = /^[\w-]+(\.[\w-]+)+(\/|$)/.test(raw) ? `https://${raw}` : raw;
    if (href && !isHref(href)) return setBad(true);
    const chain = editor.chain().focus().extendMarkRange("link");
    if (!href) chain.unsetLink().run();
    else if (editor.state.selection.empty && !active)
      chain.insertContent({ type: "text", text: href, marks: [{ type: "link", attrs: { href } }] }).run();
    else chain.setLink({ href }).run();
    setOpen(false);
  };
  return (
    <>
      <Tool
        label={t("mark.link")}
        icon={Link2}
        active={active}
        onClick={() => {
          setBad(false);
          setOpen(true);
        }}
      />
      <Dialog open={open} onClose={() => setOpen(false)} title={t("mark.link")}>
        <form onSubmit={apply} className="flex flex-col gap-4">
          <TextField
            label={t("address")}
            name="href"
            help={t("addressHelp")}
            error={bad ? t("addressBad") : undefined}
            defaultValue={String(editor.getAttributes("link").href ?? "")}
            inputMode="url"
            maxLength={2048}
          />
          <Button type="submit" className="self-start">
            {c("save")}
          </Button>
        </form>
      </Dialog>
    </>
  );
}

export function BodyTools({ editor, children }: { editor: Editor; children: React.ReactNode }) {
  const t = useTranslations("editor");
  const state = useEditorState({
    editor,
    selector: ({ editor: e }) => ({
      marks: Object.fromEntries([...MARKS.map(([m]) => m), "link"].map((m) => [m, e.isActive(m)])),
      h2: e.isActive("heading", { level: 2 }),
      h3: e.isActive("heading", { level: 3 }),
      bullet: e.isActive("bulletList"),
      ordered: e.isActive("orderedList"),
      undo: e.can().undo(),
      redo: e.can().redo(),
    }),
  });
  if (!state) return null;
  const chain = () => editor.chain().focus();
  return (
    <div
      role="toolbar"
      aria-label={t("formatting")}
      className="sticky top-0 z-10 flex items-center overflow-x-auto rounded-t-md border-border border-b bg-surface"
    >
      {children}
      <Tool
        label={t("heading", { n: 2 })}
        icon={Heading2}
        active={state.h2}
        onClick={() => chain().toggleHeading({ level: 2 }).run()}
      />
      <Tool
        label={t("heading", { n: 3 })}
        icon={Heading3}
        active={state.h3}
        onClick={() => chain().toggleHeading({ level: 3 }).run()}
      />
      <Tool
        label={t("bulletList")}
        icon={List}
        active={state.bullet}
        onClick={() => chain().toggleBulletList().run()}
      />
      <Tool
        label={t("orderedList")}
        icon={ListOrdered}
        active={state.ordered}
        onClick={() => chain().toggleOrderedList().run()}
      />
      {MARKS.map(([mark, icon]) => (
        <Tool
          key={mark}
          label={t(`mark.${mark}` as never)}
          icon={icon}
          active={state.marks[mark]}
          onClick={() => chain().toggleMark(mark).run()}
        />
      ))}
      <LinkTool editor={editor} active={state.marks.link ?? false} />
      <Tool label={t("undo")} icon={Undo2} disabled={!state.undo} onClick={() => chain().undo().run()} />
      <Tool label={t("redo")} icon={Redo2} disabled={!state.redo} onClick={() => chain().redo().run()} />
    </div>
  );
}
