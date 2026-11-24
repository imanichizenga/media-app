"use client";
import { useTranslations } from "next-intl";
import { type DragEvent, useState } from "react";
import { AssetDialog, Filters, LibraryGrid, UploadButton } from "@/components/media/library";
import { useUploads } from "@/components/media/uploads";
import { cx, PageHeader } from "@/components/ui";

export default function Media() {
  const t = useTranslations("media");
  const { add } = useUploads();
  const [filter, setFilter] = useState({ kind: "", status: "", q: "", mine: false });
  const [open, setOpen] = useState<string | null>(null);
  const [over, setOver] = useState(false);
  const drop = (e: DragEvent) => {
    e.preventDefault();
    setOver(false);
    add(e.dataTransfer.files);
  };
  return (
    <section
      aria-label={t("title")}
      onDragOver={(e) => {
        e.preventDefault();
        setOver(true);
      }}
      onDragLeave={() => setOver(false)}
      onDrop={drop}
      className={cx(
        "rounded-md outline-2 outline-offset-8",
        over ? "outline-accent outline-dashed" : "outline-transparent",
      )}
    >
      <PageHeader title={t("title")} lead={t("lead")} actions={<UploadButton>{t("upload")}</UploadButton>} />
      <Filters filter={filter} onChange={setFilter} />
      <LibraryGrid filter={filter} onPick={(a) => setOpen(a.id)} />
      <AssetDialog id={open} onClose={() => setOpen(null)} />
    </section>
  );
}
