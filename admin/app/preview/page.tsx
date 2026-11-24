"use client";
import { pageOf, pages } from "@news/screens";
import { useEffect, useState } from "react";
import { type PreviewState, READY } from "@/lib/preview";

/** The real screens with seed stories, in the colours the parent page sends. Holds nothing secret. */
export default function PreviewPage() {
  const [state, setState] = useState<PreviewState | null>(null);
  useEffect(() => {
    const listen = (e: MessageEvent) => {
      if (e.origin !== location.origin || e.source !== parent || e.data?.kind !== "preview") return;
      const next = e.data as PreviewState;
      const root = document.documentElement;
      root.dataset.theme = next.scheme;
      root.lang = next.locale;
      root.style.colorScheme = next.scheme;
      for (const [name, value] of Object.entries(next.variables)) root.style.setProperty(name, value);
      setState(next);
    };
    addEventListener("message", listen);
    if (parent !== window) parent.postMessage(READY, location.origin);
    return () => removeEventListener("message", listen);
  }, []);
  const screen = state && pages[state.screen];
  if (!screen) return null;
  // Looked at, not used: it scrolls, but nothing in it can be pressed or focused.
  return (
    <div inert className="scrollbar-none">
      {screen(pageOf(state.locale, "/preview-media", state.brand))}
    </div>
  );
}
