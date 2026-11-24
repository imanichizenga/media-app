import type { CSSProperties } from "react";

/** As the public API sends it: names are built, never spelled out (support/docs/api). */
export type ImageAsset = {
  kind: "image";
  id: string;
  alt: string;
  credit: string;
  width: number | null;
  height: number | null;
  color: string;
  focal: number[];
  base: string;
  widths: number[];
  crops: string;
};
export type VideoAsset = {
  kind: "video";
  id: string;
  alt: string;
  credit: string;
  width: number | null;
  height: number | null;
  color: string;
  duration_ms: number | null;
  hls: string;
  poster: string;
  sprite: string;
  sprite_vtt: string;
};
export type Asset = ImageAsset | VideoAsset;

/** The admin has full addresses already; readers have keys under the media host. */
export const address = (mediaBase: string, key: string) =>
  /^(https?:|\/)/.test(key) ? key : `${mediaBase}/${key}`;

const EXTENSIONS = { avif: "avif", webp: "webp", jpeg: "jpg" } as const;
export const imageUrl = (
  mediaBase: string,
  image: ImageAsset,
  width: number,
  format: keyof typeof EXTENSIONS = "jpeg",
) => {
  const best = image.widths.find((w) => w >= width) ?? image.widths.at(-1);
  return best ? address(mediaBase, `${image.base}${best}.${EXTENSIONS[format]}`) : "";
};
const srcSet = (mediaBase: string, image: ImageAsset, format: keyof typeof EXTENSIONS) =>
  image.widths.map((w) => `${address(mediaBase, image.base)}${w}.${EXTENSIONS[format]} ${w}w`).join(", ");

/** Space is held by width and height, and tinted with the picture's own colour until it arrives. */
export function Picture({
  image,
  mediaBase,
  alt,
  sizes,
  priority = false,
  className,
  style,
}: {
  image: ImageAsset;
  mediaBase: string;
  alt?: string;
  sizes: string;
  priority?: boolean;
  className?: string;
  style?: CSSProperties;
}) {
  if (image.widths.length === 0) return null;
  return (
    <picture>
      <source type="image/avif" srcSet={srcSet(mediaBase, image, "avif")} sizes={sizes} />
      <source type="image/webp" srcSet={srcSet(mediaBase, image, "webp")} sizes={sizes} />
      <img
        src={imageUrl(mediaBase, image, 1280)}
        srcSet={srcSet(mediaBase, image, "jpeg")}
        sizes={sizes}
        alt={alt ?? image.alt}
        width={image.width ?? undefined}
        height={image.height ?? undefined}
        loading={priority ? "eager" : "lazy"}
        fetchPriority={priority ? "high" : "auto"}
        decoding="async"
        className={className}
        style={{
          backgroundColor: image.color || undefined,
          objectPosition: `${(image.focal[0] ?? 500) / 10}% ${(image.focal[1] ?? 500) / 10}%`,
          ...style,
        }}
      />
    </picture>
  );
}
