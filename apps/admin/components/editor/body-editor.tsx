"use client";
import { type Block, type ContentDocument, validateDocument } from "@news/content-schema";
import { ArticleBody, type ContentContext } from "@news/ui/content";
import type { Editor } from "@tiptap/core";
import {
  EditorContent,
  type NodeViewProps,
  NodeViewWrapper,
  ReactNodeViewRenderer,
  useEditor,
} from "@tiptap/react";
import { GripVertical, Pencil, Plus, Trash2 } from "lucide-react";
import { useTranslations } from "next-intl";
import { DropdownMenu } from "radix-ui";
import { createContext, useContext, useEffect, useRef, useState } from "react";
import { Button, Dialog, Notice } from "@/components/ui";
import { useAssetMap } from "@/lib/editor/assets";
import { fromEditor, newId, toEditor } from "@/lib/editor/convert";
import { BlockIds, NewsBlock, textExtensions } from "@/lib/editor/extensions";
import { BlockForm, blank, type CardKind, EditorLocale, importYouTube, KINDS, tidy } from "./blocks";
import { BodyTools } from "./tools";

export const RenderContext = createContext<Omit<ContentContext, "assets"> | null>(null);

/** One card in the text: shown as readers will see it, opened to change it. */
function Card({ node, updateAttributes, deleteNode, selected, editor }: NodeViewProps) {
  const t = useTranslations("editor");
  const block = node.attrs.block as Block;
  const render = useContext(RenderContext);
  const assets = useAssetMap(block);
  // A card just added opens by itself; one that was never completed disappears with its form.
  const complete = valid(block);
  const [open, setOpen] = useState(!complete);
  const Icon = KINDS[block.type as CardKind];
  const name = t(`block.${block.type}` as never);
  return (
    <NodeViewWrapper
      className={`my-4 rounded-md border bg-surface ${selected ? "border-accent" : "border-border"}`}
      data-block={block.type}
    >
      <div
        contentEditable={false}
        className="flex items-center border-border border-b text-label text-text-secondary"
      >
        <span data-drag-handle className="tap grid w-11 cursor-grab place-items-center" title={t("drag")}>
          <GripVertical aria-hidden size={18} />
        </span>
        {Icon && <Icon aria-hidden size={18} />}
        <span className="flex-1 pl-2">{name}</span>
        {editor.isEditable && (
          <>
            <button
              type="button"
              className="tap grid w-11 place-items-center rounded-sm hover:bg-surface-sunken"
              aria-label={t("edit", { name })}
              onClick={() => setOpen(true)}
            >
              <Pencil aria-hidden size={18} />
            </button>
            <button
              type="button"
              className="tap grid w-11 place-items-center rounded-sm hover:bg-surface-sunken"
              aria-label={t("remove", { label: name })}
              onClick={deleteNode}
            >
              <Trash2 aria-hidden size={18} />
            </button>
          </>
        )}
      </div>
      <div contentEditable={false} className="p-4">
        {complete && render && (
          <ArticleBody
            document={{ version: 1, blocks: [block] }}
            context={{ ...render, assets, interactive: false }}
          />
        )}
      </div>
      <CardDialog
        block={block}
        name={name}
        open={open}
        onClose={() => {
          setOpen(false);
          if (!complete) deleteNode();
        }}
        onSave={(next) => {
          updateAttributes({ block: next });
          setOpen(false);
        }}
      />
    </NodeViewWrapper>
  );
}
const valid = (block: Block) => validateDocument({ version: 1, blocks: [block] }).ok;

export function CardDialog({
  block,
  name,
  open,
  onClose,
  onSave,
  saveLabel,
}: {
  block: Block;
  name: string;
  open: boolean;
  onClose: () => void;
  onSave: (block: Block) => void;
  saveLabel?: string;
}) {
  const t = useTranslations("editor");
  const c = useTranslations("common");
  const [draft, setDraft] = useState(block);
  const [bad, setBad] = useState(false);
  useEffect(() => {
    if (open) {
      setDraft(block);
      setBad(false);
    }
  }, [open, block]);
  return (
    <Dialog open={open} onClose={onClose} title={name} wide>
      <div className="flex flex-col gap-4">
        {bad && <Notice tone="danger">{t("incomplete")}</Notice>}
        <BlockForm block={draft} onChange={setDraft} />
        <Button
          className="self-start"
          onClick={() => {
            const next = tidy(draft);
            if (!valid(next)) return setBad(true);
            onSave(next);
          }}
        >
          {saveLabel ?? c("save")}
        </Button>
      </div>
    </Dialog>
  );
}

function InsertMenu({ editor, kinds }: { editor: Editor; kinds: CardKind[] }) {
  const t = useTranslations("editor");
  return (
    <DropdownMenu.Root>
      <DropdownMenu.Trigger asChild>
        <button
          type="button"
          className="tap flex shrink-0 items-center gap-2 rounded-sm px-3 text-accent text-label hover:bg-surface-sunken"
        >
          <Plus aria-hidden size={18} /> {t("insert")}
        </button>
      </DropdownMenu.Trigger>
      <DropdownMenu.Portal>
        <DropdownMenu.Content
          align="start"
          className="z-40 max-h-(--radix-dropdown-menu-content-available-height) overflow-y-auto rounded-md border border-border bg-surface-raised p-2 shadow-lg"
        >
          {kinds.map((kind) => {
            const Icon = KINDS[kind];
            return (
              <DropdownMenu.Item
                key={kind}
                onSelect={() => {
                  const block = blank(kind);
                  editor
                    .chain()
                    .focus()
                    .insertContent({ type: "newsBlock", attrs: { id: block.id, block } })
                    .run();
                }}
                className="tap flex cursor-pointer items-center gap-3 rounded-sm px-3 outline-none data-[highlighted]:bg-accent-soft data-[highlighted]:text-accent"
              >
                <Icon aria-hidden size={18} /> {t(`block.${kind}`)}
              </DropdownMenu.Item>
            );
          })}
        </DropdownMenu.Content>
      </DropdownMenu.Portal>
    </DropdownMenu.Root>
  );
}

const YOUTUBE = /^\s*(https?:\/\/)?((www|m|music)\.)?(youtube(-nocookie)?\.com|youtu\.be)\/\S+\s*$/i;

export function BodyEditor({
  locale,
  initial,
  editable,
  isLiveBlog,
  onChange,
}: {
  locale: "sw" | "en";
  initial: ContentDocument;
  editable: boolean;
  isLiveBlog: boolean;
  onChange: (body: ContentDocument) => void;
}) {
  const t = useTranslations("editor");
  const latest = useRef(onChange);
  latest.current = onChange;
  const editor = useEditor({
    extensions: [
      ...textExtensions(t("placeholder")),
      BlockIds,
      NewsBlock.extend({ addNodeView: () => ReactNodeViewRenderer(Card) }),
    ],
    // Styles live in globals.css: the policy allows no injected style elements.
    injectCSS: false,
    immediatelyRender: false,
    editable,
    content: toEditor(initial),
    editorProps: {
      attributes: {
        role: "textbox",
        "aria-multiline": "true",
        "aria-label": t("body"),
        class: "editor-body",
        lang: locale,
      },
      handlePaste: (view, event) => {
        const text = event.clipboardData?.getData("text/plain") ?? "";
        if (!YOUTUBE.test(text)) return false;
        importYouTube(text.trim())
          .then((v) => {
            const id = newId();
            const block = {
              type: "youtube",
              id,
              videoId: v.video_id,
              title: v.title,
              ...(v.start ? { start: v.start } : {}),
              ...(v.vertical ? { vertical: true } : {}),
            };
            const type = view.state.schema.nodes.newsBlock;
            if (type) view.dispatch(view.state.tr.replaceSelectionWith(type.create({ id, block })));
          })
          .catch(() => view.dispatch(view.state.tr.insertText(text.trim())));
        return true;
      },
    },
    onUpdate: ({ editor }) => latest.current(fromEditor(editor.getJSON())),
  });
  useEffect(() => {
    if (editor && editor.isEditable !== editable) editor.setEditable(editable, false);
  }, [editor, editable]);
  const kinds = (Object.keys(KINDS) as CardKind[]).filter((k) => k !== "live_update" || isLiveBlog);
  return (
    <EditorLocale value={locale}>
      <div className="rounded-md border border-border bg-surface">
        {editor ? (
          <>
            {editable && (
              <BodyTools editor={editor}>
                <InsertMenu editor={editor} kinds={kinds} />
              </BodyTools>
            )}
            <EditorContent editor={editor} />
          </>
        ) : (
          <BodyEditor.Skeleton />
        )}
      </div>
    </EditorLocale>
  );
}
BodyEditor.Skeleton = () => (
  <div className="min-h-96 p-5">
    <ArticleBody.Skeleton />
  </div>
);
