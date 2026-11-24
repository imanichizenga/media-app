"use client";
import type { Block } from "@news/content-schema";
import type { Asset as MediaAsset } from "@news/ui/media";
import { useQueries } from "@tanstack/react-query";
import { call, client } from "@/lib/api";
import { contentKeys } from "@/lib/queries";
import type { Asset } from "@/lib/upload";

export function assetsOf(block: Block): string[] {
  switch (block.type) {
    case "image":
    case "video":
      return block.asset ? [block.asset] : [];
    case "gallery":
      return block.items.map((i) => i.asset);
    case "live_update":
      return block.blocks.flatMap((b) => assetsOf(b as Block));
    default:
      return [];
  }
}

/** The library's view of a file, as the shared renderer expects it: one address instead of a set of sizes. */
export function forRender(asset: Asset): MediaAsset {
  const common = {
    id: asset.id,
    alt: asset.alt_sw || asset.alt_en,
    credit: asset.credit,
    width: asset.width,
    height: asset.height,
    color: asset.dominant_color,
  };
  if (asset.kind === "video")
    return {
      ...common,
      kind: "video",
      duration_ms: asset.duration_ms,
      hls: asset.hls_url,
      poster: asset.thumb_url,
      sprite: "",
      sprite_vtt: "",
    };
  // Addresses end in `<width>.webp`; the folder before it holds the other sizes.
  const match = /^(.*\/)(\d+)\.webp$/.exec(asset.large_url);
  return {
    ...common,
    kind: "image",
    focal: [asset.focal_x, asset.focal_y],
    base: match?.[1] ?? "",
    widths: match ? [Number(match[2])] : [],
    crops: "",
  };
}

export function useAssetMap(block: Block): Record<string, MediaAsset> {
  const ids = [...new Set(assetsOf(block))];
  return useQueries({
    queries: ids.map((id) => ({
      queryKey: contentKeys.asset(id),
      queryFn: () =>
        call(() => client.GET("/api/v1/media/{asset_id}", { params: { path: { asset_id: id } } })),
      staleTime: 60_000,
    })),
    combine: (results) =>
      Object.fromEntries(
        results.flatMap((r) => (r.data ? [[r.data.asset.id, forRender(r.data.asset)]] : [])),
      ),
  });
}
