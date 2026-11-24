"use client";
import { useEffect, useRef, useState } from "react";
import { cx } from "@/components/ui";
import { type PreviewState, READY } from "@/lib/preview";

/** A real window of the given size, scaled down to the width it is given. `className` carries the same shape: the
 * policy allows no style attribute in the server's HTML, so the frame itself appears once its box is measured. */
export function PreviewFrame({
  state,
  width,
  height,
  title,
  className,
}: {
  state: Omit<PreviewState, "kind">;
  width: number;
  height: number;
  title: string;
  className?: string;
}) {
  const frame = useRef<HTMLIFrameElement>(null);
  const box = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(0);
  const [ready, setReady] = useState(false);
  useEffect(() => {
    const listen = (e: MessageEvent) => {
      if (e.origin === location.origin && e.source === frame.current?.contentWindow && e.data === READY)
        setReady(true);
    };
    addEventListener("message", listen);
    return () => removeEventListener("message", listen);
  }, []);
  useEffect(() => {
    if (ready) frame.current?.contentWindow?.postMessage({ kind: "preview", ...state }, location.origin);
  }, [ready, state]);
  useEffect(() => {
    if (!box.current) return;
    const watch = new ResizeObserver(([entry]) => setScale((entry?.contentRect.width ?? 0) / width));
    watch.observe(box.current);
    return () => watch.disconnect();
  }, [width]);
  return (
    <div
      ref={box}
      className={cx("relative overflow-hidden border border-border bg-surface-sunken", className)}
    >
      {!ready && <span aria-hidden className="bone absolute inset-0 block! size-full rounded-none!" />}
      {scale > 0 && (
        <iframe
          ref={frame}
          src="/preview"
          title={title}
          tabIndex={-1}
          className={cx("absolute top-0 left-0 max-w-none origin-top-left", !ready && "invisible")}
          style={{ width, height, transform: `scale(${scale})` }}
        />
      )}
    </div>
  );
}
