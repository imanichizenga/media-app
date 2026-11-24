"use client";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useTranslations } from "next-intl";
import { type FormEvent, useState } from "react";
import { MediaPicker, Thumb } from "@/components/media/library";
import {
  Bone,
  Button,
  Card,
  cx,
  ErrorState,
  Field,
  FormError,
  Notice,
  PageHeader,
  TextField,
} from "@/components/ui";
import { call, client } from "@/lib/api";
import { contentKeys, useAsset, useSession } from "@/lib/queries";

/** What readers see when they tap a byline. Everyone writes their own. */
export default function AuthorPage() {
  const t = useTranslations("author");
  const { data: session } = useSession();
  const id = session?.user.id ?? "";
  const { data, error, refetch } = useQuery({
    queryKey: contentKeys.author(id),
    queryFn: () => call(() => client.GET("/api/v1/authors/{user_id}", { params: { path: { user_id: id } } })),
    enabled: Boolean(id),
  });
  return (
    <>
      <PageHeader title={t("title")} lead={t("lead")} />
      <Card>
        {error ? (
          <ErrorState error={error} retry={refetch} />
        ) : data ? (
          <AuthorForm key={data.slug} id={id} author={data} />
        ) : (
          <div aria-hidden className="flex max-w-xl flex-col gap-4" data-skeleton="form">
            <span className="flex items-center gap-4">
              <span className="bone size-24 rounded-full!" />
              <span className="tap bone w-32" />
            </span>
            {/* Two short fields, then four tall ones. */}
            {[0, 1, 2, 3, 4, 5].map((i) => (
              <span key={i} className="flex flex-col gap-1">
                <span className="text-label">
                  <Bone className="w-32" />
                </span>
                <span className={cx("bone block! w-full", i < 2 ? "tap" : "h-28")} />
              </span>
            ))}
          </div>
        )}
      </Card>
    </>
  );
}

type Author = NonNullable<Awaited<ReturnType<typeof load>>>;
const load = (id: string) =>
  call(() => client.GET("/api/v1/authors/{user_id}", { params: { path: { user_id: id } } }));

function AuthorForm({ id, author }: { id: string; author: Author }) {
  const t = useTranslations("author");
  const e = useTranslations("editor");
  const c = useTranslations("common");
  const queries = useQueryClient();
  const [avatar, setAvatar] = useState(author.avatar?.id ?? "");
  const picture = useAsset(avatar || null);
  const [open, setOpen] = useState(false);
  const [pending, setPending] = useState(false);
  const [problem, setProblem] = useState<unknown>(null);
  const [saved, setSaved] = useState(false);
  const lines = (form: FormData, name: string) =>
    String(form.get(name) ?? "")
      .split("\n")
      .map((x) => x.trim())
      .filter(Boolean);
  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const text = (name: string) => String(form.get(name) ?? "");
    setPending(true);
    setProblem(null);
    setSaved(false);
    try {
      const next = await call(() =>
        client.PUT("/api/v1/authors/{user_id}", {
          params: { path: { user_id: id } },
          body: {
            title_sw: text("title_sw"),
            title_en: text("title_en"),
            bio_sw: text("bio_sw"),
            bio_en: text("bio_en"),
            expertise: lines(form, "expertise"),
            links: lines(form, "links"),
            avatar: avatar || null,
          },
        }),
      );
      queries.setQueryData(contentKeys.author(id), next);
      setSaved(true);
    } catch (err) {
      setProblem(err);
    } finally {
      setPending(false);
    }
  };
  const area = (label: string, name: string, value: string, help?: string, max?: number) => (
    <Field label={label} help={help}>
      {(p) => <textarea name={name} rows={4} maxLength={max} defaultValue={value} {...p} />}
    </Field>
  );
  return (
    <form onSubmit={submit} className="flex max-w-xl flex-col gap-4">
      <FormError error={problem} />
      {saved && <Notice tone="success">{t("saved")}</Notice>}
      <div className="flex items-center gap-4">
        {picture.data ? (
          <Thumb asset={picture.data.asset} className="size-24 rounded-full!" />
        ) : (
          <span className="grid size-24 place-items-center rounded-full bg-brand-soft font-serif text-brand-text text-headline-l">
            {author.display_name.slice(0, 1)}
          </span>
        )}
        <Button variant="secondary" onClick={() => setOpen(true)}>
          {e(avatar ? "change" : "choose.image")}
        </Button>
        {avatar && (
          <Button variant="ghost" onClick={() => setAvatar("")}>
            {e("removeIt")}
          </Button>
        )}
      </div>
      <MediaPicker kind="image" open={open} onClose={() => setOpen(false)} onPick={(a) => setAvatar(a.id)} />
      <TextField label={t("titleSw")} name="title_sw" defaultValue={author.title_sw} maxLength={120} />
      <TextField label={t("titleEn")} name="title_en" defaultValue={author.title_en} maxLength={120} />
      {area(t("bioSw"), "bio_sw", author.bio_sw, undefined, 2000)}
      {area(t("bioEn"), "bio_en", author.bio_en, undefined, 2000)}
      {area(t("expertise"), "expertise", author.expertise.join("\n"), t("onePerLine"))}
      {area(t("links"), "links", author.links.join("\n"), t("linksHelp"))}
      <Button type="submit" pending={pending} className="self-start">
        {c("save")}
      </Button>
    </form>
  );
}
