/// <reference path="./hls-light.d.ts" />
"use client";
import { Play } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { address, type VideoAsset } from "./media";

/** Adaptive HLS. Nothing is downloaded before the reader asks: not the stream, not the player. */
export function VideoPlayer({
  video,
  mediaBase,
  playLabel,
  errorLabel,
}: {
  video: VideoAsset;
  mediaBase: string;
  playLabel: string;
  errorLabel: string;
}) {
  const element = useRef<HTMLVideoElement>(null);
  const [started, setStarted] = useState(false);
  const [failed, setFailed] = useState(false);
  useEffect(() => {
    const el = element.current;
    if (!started || !el) return;
    const source = address(mediaBase, video.hls);
    let destroy = () => {};
    let cancelled = false;
    (async () => {
      const { default: Hls } = await import("hls.js/light");
      if (cancelled) return;
      if (Hls.isSupported()) {
        // No worker: it would need blob: scripts, which the admin's policy rightly refuses.
        const hls = new Hls({ enableWorker: false, capLevelToPlayerSize: true });
        hls.on(Hls.Events.ERROR, (_, data) => data.fatal && setFailed(true));
        hls.loadSource(source);
        hls.attachMedia(el);
        destroy = () => hls.destroy();
      } else el.src = source; // Safari plays HLS itself
      await el.play().catch(() => {});
    })().catch(() => setFailed(true));
    return () => {
      cancelled = true;
      destroy();
    };
  }, [started, video.hls, mediaBase]);
  const ratio = video.width && video.height ? `${video.width} / ${video.height}` : "16 / 9";
  return (
    <div
      className="relative mx-auto max-h-[80dvh] overflow-hidden rounded-md bg-black"
      style={{ aspectRatio: ratio }}
    >
      {/* biome-ignore lint/a11y/useMediaCaption: captions arrive with the caption track (spec §6, M7) */}
      <video
        ref={element}
        poster={video.poster ? address(mediaBase, video.poster) : undefined}
        controls={started}
        playsInline
        preload="none"
        aria-label={video.alt}
        className="size-full object-contain"
      />
      {!started && (
        <button
          type="button"
          onClick={() => setStarted(true)}
          aria-label={playLabel}
          className="absolute inset-0 grid place-items-center bg-black/20 text-white transition-colors hover:bg-black/30"
        >
          <span className="grid size-16 place-items-center rounded-full bg-black/60">
            <Play aria-hidden size={28} fill="currentColor" />
          </span>
        </button>
      )}
      {failed && (
        <p role="alert" className="absolute inset-x-0 bottom-0 bg-black/80 p-3 text-center text-white">
          {errorLabel}
        </p>
      )}
    </div>
  );
}

/** A picture until it is pressed: YouTube sets no cookie and loads no script before that. */
export function YouTubeFacade({
  videoId,
  title,
  start = 0,
  vertical = false,
  poster,
  interactive,
  playLabel,
}: {
  videoId: string;
  title: string;
  start?: number;
  vertical?: boolean;
  poster?: string;
  interactive: boolean;
  playLabel: string;
}) {
  const [open, setOpen] = useState(false);
  const inner = (
    <>
      {poster && (
        <img src={poster} alt="" loading="lazy" className="absolute inset-0 size-full object-cover" />
      )}
      <span className="absolute inset-0 grid place-items-center bg-black/30">
        <span className="grid h-12 w-17 place-items-center rounded-md bg-black/75">
          <Play aria-hidden size={24} fill="currentColor" />
        </span>
      </span>
      {title && (
        <span className="absolute inset-x-0 bottom-0 bg-linear-to-t from-black/80 to-transparent p-4 pt-12 text-left text-label">
          {title}
        </span>
      )}
    </>
  );
  const box = `relative block w-full overflow-hidden rounded-md bg-black text-white ${vertical ? "mx-auto aspect-9/16 max-w-sm" : "aspect-video"}`;
  if (open)
    return (
      <iframe
        className={box}
        src={`https://www.youtube-nocookie.com/embed/${videoId}?autoplay=1&start=${start}`}
        title={title || playLabel}
        allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
        referrerPolicy="strict-origin-when-cross-origin"
      />
    );
  const label = `${playLabel}: ${title || "YouTube"}`;
  return interactive ? (
    <button type="button" onClick={() => setOpen(true)} aria-label={label} className={box}>
      {inner}
    </button>
  ) : (
    <a
      href={`https://www.youtube.com/watch?v=${videoId}&t=${start}s`}
      target="_blank"
      rel="noreferrer noopener"
      aria-label={label}
      className={box}
    >
      {inner}
    </a>
  );
}
