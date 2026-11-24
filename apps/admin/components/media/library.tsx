"use client";
import { VideoPlayer } from "@news/ui/player";
import { useQueryClient } from "@tanstack/react-query";
import { Check, Film, ImageIcon, LoaderCircle, TriangleAlert, Upload } from "lucide-react";
import Link from "next/link";
import { useFormatter, useTranslations } from "next-intl";
import {
  type FormEvent,
  type KeyboardEvent,
  type PointerEvent,
  type ReactNode,
  useRef,
  useState,
} from "react";
import {
  Badge,
  Bone,
  Button,
  Card,
  cx,
  Dialog,
  Empty,
  ErrorState,
  FormError,
  Notice,
  TextField,
  type Tone,
} from "@/components/ui";
import { call, client } from "@/lib/api";
import { contentKeys, isBusy, useAsset, useAssetSignal, useCan, usePaged, useSession } from "@/lib/queries";
import type { Asset } from "@/lib/upload";
import { useUploads } from "./uploads";

const TONES: Record<string, Tone> = { ready: "success", failed: "danger", rejected: "danger" };
export const duration = (ms: number | null) =>
  ms === null ? "" : `${Math.floor(ms / 60_000)}:${String(Math.floor(ms / 1000) % 60).padStart(2, "0")}`;

const size = (bytes: number, format: (n: number, o: object) => string) =>
  bytes < 1024 ** 2
    ? `${format(Math.ceil(bytes / 1024), {})} KB`
    : `${format(bytes / 1024 ** 2, { maximumFractionDigits: 1 })} MB`;

/** Logos and banners: cropping one to a tile would leave nothing to recognise. */
const wide = ({ width, height }: Asset) => Boolean(width && height) && (width ?? 0) > (height ?? 0) * 2.4;

/** A square that says what the file is, and how far it has come. */
export function Thumb({ asset, className }: { asset: Asset; className?: string }) {
  const t = useTranslations("media");
  useAssetSignal(asset.id, asset.status);
  const Icon = isBusy(asset.status)
    ? LoaderCircle
    : asset.status === "ready"
      ? asset.kind === "video"
        ? Film
        : ImageIcon
      : TriangleAlert;
  return (
    <span className={cx("relative block overflow-hidden rounded-sm bg-surface-sunken", className)}>
      {asset.thumb_url ? (
        <img
          src={asset.thumb_url}
          alt=""
          loading="lazy"
          className={cx("absolute inset-0 size-full", wide(asset) ? "object-contain p-2" : "object-cover")}
          style={{ objectPosition: wide(asset) ? "center" : `${asset.focal_x / 10}% ${asset.focal_y / 10}%` }}
        />
      ) : (
        <span className="absolute inset-0 grid place-items-center text-text-tertiary">
          <Icon aria-hidden size={24} className={isBusy(asset.status) ? "motion-safe:animate-spin" : ""} />
        </span>
      )}
      {asset.kind === "video" && asset.duration_ms !== null && (
        <span className="absolute right-1 bottom-1 rounded-sm bg-black/75 px-1 text-caption text-white">
          {duration(asset.duration_ms)}
        </span>
      )}
      {asset.status !== "ready" && (
        <span className="absolute bottom-1 left-1">
          <Badge tone={TONES[asset.status]}>{t(`status.${asset.status}`)}</Badge>
        </span>
      )}
    </span>
  );
}

type Filter = { kind: string; status: string; q: string; mine: boolean };
export function useLibrary(filter: Filter, enabled = true) {
  return usePaged(
    [...contentKeys.media, "list", filter],
    (cursor) =>
      call(() =>
        client.GET("/api/v1/media", {
          params: {
            query: {
              ...(filter.kind ? { kind: filter.kind } : {}),
              ...(filter.status ? { status: filter.status } : {}),
              ...(filter.q ? { q: filter.q } : {}),
              ...(filter.mine ? { mine: true } : {}),
              ...(cursor ? { cursor } : {}),
            },
          },
        }),
      ),
    enabled,
  );
}

const GRID = "grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5";

export function LibraryGrid({
  filter,
  onPick,
  picked,
}: {
  filter: Filter;
  onPick: (asset: Asset) => void;
  picked?: Set<string>;
}) {
  const t = useTranslations("media");
  const c = useTranslations("common");
  const list = useLibrary(filter);
  if (list.error) return <ErrorState error={list.error} retry={list.refetch} />;
  if (list.rows?.length === 0)
    return (
      <Card>
        <Empty title={t("empty")} body={t("emptyBody")} />
      </Card>
    );
  return (
    <>
      <ul className={GRID}>
        {list.rows
          ? list.rows.map((asset) => (
              <li key={asset.id}>
                <button
                  type="button"
                  onClick={() => onPick(asset)}
                  aria-pressed={picked ? picked.has(asset.id) : undefined}
                  className="group relative block w-full rounded-sm text-left"
                >
                  <Thumb
                    asset={asset}
                    className="aspect-4/3 w-full outline-2 outline-transparent -outline-offset-2 transition-[outline-color] group-hover:outline-accent group-aria-pressed:outline-accent"
                  />
                  {picked?.has(asset.id) && (
                    <span className="absolute top-2 right-2 grid size-6 place-items-center rounded-full bg-accent text-on-accent">
                      <Check aria-hidden size={16} />
                    </span>
                  )}
                  <span className="block truncate pt-1 text-label">
                    {asset.alt_sw || asset.alt_en || asset.filename}
                  </span>
                  <span className="block truncate text-caption text-text-secondary">
                    {asset.credit || t("noCredit")}
                  </span>
                </button>
              </li>
            ))
          : Array.from({ length: 15 }, (_, i) => (
              // biome-ignore lint/suspicious/noArrayIndexKey: static placeholders
              <li key={i} data-skeleton="tile">
                <span className="bone block! aspect-4/3 w-full" />
                <span className="block pt-1 text-label">
                  <Bone className="w-3/4" />
                </span>
                <span className="block text-caption">
                  <Bone className="w-1/2" />
                </span>
              </li>
            ))}
      </ul>
      {list.hasNextPage && (
        <Button
          variant="secondary"
          className="mt-4"
          pending={list.isFetchingNextPage}
          onClick={() => list.fetchNextPage()}
        >
          {c("more")}
        </Button>
      )}
    </>
  );
}

export function Filters({
  filter,
  onChange,
  kinds = true,
}: {
  filter: Filter;
  onChange: (f: Filter) => void;
  kinds?: boolean;
}) {
  const t = useTranslations("media");
  const control = "tap rounded-sm border border-border-strong bg-surface px-3 text-body-m text-text-primary";
  return (
    <div className="mb-4 flex flex-wrap gap-3">
      <input
        type="search"
        aria-label={t("search")}
        placeholder={t("search")}
        value={filter.q}
        onChange={(e) => onChange({ ...filter, q: e.target.value })}
        className={cx(control, "min-w-0 flex-1 basis-48")}
      />
      {kinds && (
        <select
          aria-label={t("kindLabel")}
          value={filter.kind}
          onChange={(e) => onChange({ ...filter, kind: e.target.value })}
          className={control}
        >
          <option value="">{t("allKinds")}</option>
          <option value="image">{t("kind.image")}</option>
          <option value="video">{t("kind.video")}</option>
        </select>
      )}
      <label className="tap flex items-center gap-2 text-label">
        <input
          type="checkbox"
          checked={filter.mine}
          onChange={(e) => onChange({ ...filter, mine: e.target.checked })}
          className="size-5"
        />
        {t("mine")}
      </label>
    </div>
  );
}

export function UploadButton({
  accept = "image/*,video/*",
  multiple = true,
  onDone,
  variant = "primary",
  children,
}: {
  accept?: string;
  multiple?: boolean;
  onDone?: (id: string) => void;
  variant?: "primary" | "secondary";
  children: ReactNode;
}) {
  const { add } = useUploads();
  const input = useRef<HTMLInputElement>(null);
  return (
    <>
      <Button variant={variant} onClick={() => input.current?.click()}>
        <Upload aria-hidden size={18} /> {children}
      </Button>
      <input
        ref={input}
        type="file"
        hidden
        accept={accept}
        multiple={multiple}
        onChange={(e) => {
          add(e.target.files ?? [], onDone);
          e.target.value = "";
        }}
      />
    </>
  );
}

/** Choose from the library, or upload and choose in one go. */
export function MediaPicker({
  kind,
  open,
  onClose,
  onPick,
}: {
  kind: "image" | "video";
  open: boolean;
  onClose: () => void;
  onPick: (asset: Asset) => void;
}) {
  const t = useTranslations("media");
  const [filter, setFilter] = useState<Filter>({ kind, status: "", q: "", mine: false });
  return (
    <Dialog open={open} onClose={onClose} title={t(`choose.${kind}`)} wide>
      <div className="mb-4">
        <UploadButton accept={`${kind}/*`} multiple={false} variant="secondary">
          {t("upload")}
        </UploadButton>
      </div>
      <Filters filter={filter} onChange={setFilter} kinds={false} />
      <LibraryGrid
        filter={{ ...filter, kind }}
        onPick={(asset) => {
          onPick(asset);
          onClose();
        }}
      />
    </Dialog>
  );
}

const clamp = (n: number) => Math.min(1000, Math.max(0, Math.round(n)));
/** What every crop must keep. Press, drag, or use the arrow keys. */
function FocalPoint({
  asset,
  x,
  y,
  onChange,
}: {
  asset: Asset;
  x: number;
  y: number;
  onChange: (x: number, y: number) => void;
}) {
  const t = useTranslations("media");
  const place = (e: PointerEvent<HTMLElement>) => {
    const box = e.currentTarget.getBoundingClientRect();
    onChange(
      clamp(((e.clientX - box.left) / box.width) * 1000),
      clamp(((e.clientY - box.top) / box.height) * 1000),
    );
  };
  const move = (e: KeyboardEvent) => {
    const step = { ArrowLeft: [-20, 0], ArrowRight: [20, 0], ArrowUp: [0, -20], ArrowDown: [0, 20] }[e.key];
    if (!step) return;
    e.preventDefault();
    onChange(clamp(x + (step[0] ?? 0)), clamp(y + (step[1] ?? 0)));
  };
  return (
    <div>
      <div
        role="slider"
        tabIndex={0}
        aria-label={t("focal")}
        aria-valuetext={`${Math.round(x / 10)}%, ${Math.round(y / 10)}%`}
        aria-valuenow={x}
        aria-valuemin={0}
        aria-valuemax={1000}
        onKeyDown={move}
        onPointerDown={(e) => {
          e.currentTarget.setPointerCapture(e.pointerId);
          place(e);
        }}
        onPointerMove={(e) => e.buttons === 1 && place(e)}
        className="relative cursor-crosshair touch-none overflow-hidden rounded-sm"
      >
        <img src={asset.large_url} alt="" draggable={false} className="block w-full" />
        <span
          className="pointer-events-none absolute size-8 -translate-x-1/2 -translate-y-1/2 rounded-full border-3 border-white shadow-[0_0_0_2px_rgb(0_0_0/0.6)]"
          style={{ left: `${x / 10}%`, top: `${y / 10}%` }}
        />
      </div>
      <p className="pt-1 text-caption text-text-secondary">{t("focalHelp")}</p>
    </div>
  );
}

export function AssetDialog({ id, onClose }: { id: string | null; onClose: () => void }) {
  const t = useTranslations("media");
  return (
    <Dialog open={id !== null} onClose={onClose} title={t("details")} wide>
      {id && <AssetDetails key={id} id={id} onClose={onClose} />}
    </Dialog>
  );
}

function AssetDetails({ id, onClose }: { id: string; onClose: () => void }) {
  const t = useTranslations("media");
  const c = useTranslations("common");
  const format = useFormatter();
  const queries = useQueryClient();
  const can = useCan();
  const { data: session } = useSession();
  const { data, error, refetch } = useAsset(id);
  const [focal, setFocal] = useState<[number, number] | null>(null);
  const [pending, setPending] = useState("");
  const [problem, setProblem] = useState<unknown>(null);
  const [saved, setSaved] = useState(false);
  if (error) return <ErrorState error={error} retry={refetch} />;
  if (!data) return <AssetDetails.Skeleton />;
  const { asset } = data;
  const mine = asset.uploaded_by?.id === session?.user.id;
  const editable = mine || can("media.manage");
  const path = { params: { path: { asset_id: id } } };
  const [x, y] = focal ?? [asset.focal_x, asset.focal_y];

  async function act(name: string, run: () => Promise<unknown>, close = false) {
    setPending(name);
    setProblem(null);
    setSaved(false);
    try {
      await run();
      await queries.invalidateQueries({ queryKey: contentKeys.media });
      if (close) onClose();
      else setSaved(name === "save");
    } catch (err) {
      setProblem(err);
    } finally {
      setPending("");
    }
  }
  const save = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    const body = {
      ...Object.fromEntries(
        ["alt_sw", "alt_en", "credit", "license"].map((k) => [k, String(form.get(k) ?? "")]),
      ),
      ...(asset.kind === "image" ? { focal_x: x, focal_y: y } : {}),
    };
    void act("save", () => call(() => client.PATCH("/api/v1/media/{asset_id}", { ...path, body })));
  };
  const used = data.posts.length + data.elsewhere.length;
  return (
    <div className="grid gap-6 md:grid-cols-2">
      <div className="flex flex-col gap-4">
        {asset.status !== "ready" ? (
          <>
            <Thumb asset={asset} className="aspect-4/3 w-full" />
            {asset.error_code && (
              <Notice tone="danger">
                {t.has(`error.${asset.error_code}` as never)
                  ? t(`error.${asset.error_code}` as never)
                  : t("error.processing_failed")}
              </Notice>
            )}
            {asset.status === "failed" && editable && (
              <Button
                variant="secondary"
                pending={pending === "retry"}
                onClick={() =>
                  act("retry", () => call(() => client.POST("/api/v1/media/{asset_id}/retry", path)))
                }
              >
                {c("retry")}
              </Button>
            )}
          </>
        ) : asset.kind === "image" ? (
          <FocalPoint asset={asset} x={x} y={y} onChange={(a, b) => editable && setFocal([a, b])} />
        ) : (
          <VideoPlayer
            playLabel={t("play")}
            errorLabel={t("playError")}
            mediaBase=""
            video={{
              kind: "video",
              id: asset.id,
              alt: asset.alt_sw || asset.filename,
              credit: asset.credit,
              width: asset.width,
              height: asset.height,
              color: "",
              duration_ms: asset.duration_ms,
              hls: asset.hls_url,
              poster: asset.thumb_url,
              sprite: "",
              sprite_vtt: "",
            }}
          />
        )}
        <dl className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-1 text-caption text-text-secondary">
          <dt>{t("file")}</dt>
          <dd className="break-all">{asset.filename}</dd>
          <dt>{t("size")}</dt>
          <dd>
            {size(asset.bytes, format.number)}
            {asset.width ? ` · ${asset.width}×${asset.height}` : ""}
            {asset.duration_ms ? ` · ${duration(asset.duration_ms)}` : ""}
          </dd>
          <dt>{t("by")}</dt>
          <dd>{asset.uploaded_by?.display_name ?? "—"}</dd>
        </dl>
      </div>
      <div className="flex flex-col gap-4">
        <form onSubmit={save} className="flex flex-col gap-4">
          <FormError error={problem} />
          {saved && <Notice tone="success">{t("saved")}</Notice>}
          <TextField
            label={t("altSw")}
            help={t("altHelp")}
            name="alt_sw"
            defaultValue={asset.alt_sw}
            maxLength={500}
            disabled={!editable}
          />
          <TextField
            label={t("altEn")}
            name="alt_en"
            defaultValue={asset.alt_en}
            maxLength={500}
            disabled={!editable}
          />
          <TextField
            label={t("credit")}
            help={t("creditHelp")}
            name="credit"
            defaultValue={asset.credit}
            maxLength={200}
            disabled={!editable}
          />
          <TextField
            label={t("license")}
            name="license"
            defaultValue={asset.license}
            maxLength={200}
            disabled={!editable}
          />
          {editable && (
            <Button type="submit" pending={pending === "save"} className="self-start">
              {c("save")}
            </Button>
          )}
        </form>
        <section>
          <h3 className="pb-1 text-title">{t("usedIn", { n: used })}</h3>
          <ul className="flex flex-col">
            {data.posts.map((post) => (
              <li key={post.id}>
                <Link href={`/content/${post.id}`} className="tap flex items-center text-accent">
                  {post.headline || t("untitled")}
                </Link>
              </li>
            ))}
            {data.elsewhere.map((name) => (
              <li key={name} className="tap flex items-center">
                {t(`elsewhere.${name}` as never)}
              </li>
            ))}
          </ul>
        </section>
        {editable && used === 0 && (
          <Button
            variant="danger"
            className="self-start"
            pending={pending === "delete"}
            onClick={() =>
              act("delete", () => call(() => client.DELETE("/api/v1/media/{asset_id}", path)), true)
            }
          >
            {t("delete")}
          </Button>
        )}
      </div>
    </div>
  );
}
AssetDetails.Skeleton = () => (
  <div aria-hidden className="grid gap-6 md:grid-cols-2">
    <span className="bone block! aspect-4/3 w-full" />
    <div className="flex flex-col gap-4">
      {[0, 1, 2, 3].map((i) => (
        <span key={i} className="tap bone block! w-full" />
      ))}
    </div>
  </div>
);
