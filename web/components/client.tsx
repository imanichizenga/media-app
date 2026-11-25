"use client";
import { ALargeSmall, Bookmark, Share2, Smartphone, SunMoon, X } from "@news/ui/icons";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import type { Kept } from "./kept";
import { keep, kept, onKept, unkeep } from "./kept";

const ICON = "tap grid w-11 place-items-center rounded-sm hover:bg-current/10";
const root = () => document.documentElement;
function remember(key: string, value: string) {
  try {
    if (value) localStorage.setItem(key, value);
    else localStorage.removeItem(key);
  } catch {
    // A private window: it lasts as long as the page.
  }
}

/** As the phone, light, dark, and round again. The choice stays in this browser. */
export function SchemeButton({ label }: { label: string }) {
  return (
    <button
      type="button"
      aria-label={label}
      className={ICON}
      onClick={() => {
        const dark =
          root().dataset.theme === "dark" ||
          (!root().dataset.theme && matchMedia("(prefers-color-scheme: dark)").matches);
        root().dataset.theme = dark ? "light" : "dark";
        remember("scheme", root().dataset.theme);
      }}
    >
      <SunMoon size={20} />
    </button>
  );
}

export function TextSizeButton({ label }: { label: string }) {
  return (
    <button
      type="button"
      aria-label={label}
      className={ICON}
      onClick={() => {
        const next = (Number(root().dataset.text ?? 0) + 1) % 4;
        if (next) root().dataset.text = String(next);
        else delete root().dataset.text;
        remember("text", next ? String(next) : "");
      }}
    >
      <ALargeSmall size={22} />
    </button>
  );
}

export function ShareButton({
  label,
  done,
  title,
  className = ICON,
}: {
  label: string;
  done: string;
  title: string;
  className?: string;
}) {
  const [said, say] = useState("");
  return (
    <button
      type="button"
      aria-label={label}
      className={className}
      onClick={async () => {
        const url = location.origin + location.pathname;
        try {
          if (navigator.share) await navigator.share({ title, url });
          else {
            await navigator.clipboard.writeText(url);
            say(done);
            setTimeout(() => say(""), 2500);
          }
        } catch {
          // The reader closed it.
        }
      }}
    >
      <Share2 size={21} />
      <span
        role="status"
        className={
          said
            ? "fixed bottom-24 left-1/2 z-40 -translate-x-1/2 rounded-full bg-text-primary px-4 py-2 text-bg text-label"
            : "sr-only"
        }
      >
        {said}
      </span>
    </button>
  );
}

export function SaveButton({
  story,
  save,
  unsave,
  className = ICON,
}: {
  story: Kept;
  save: string;
  unsave: string;
  className?: string;
}) {
  const [on, set] = useState(false);
  useEffect(() => {
    const look = () => set(kept().some((k) => k.path === story.path));
    look();
    return onKept(look);
  }, [story.path]);
  return (
    <button
      type="button"
      aria-label={on ? unsave : save}
      aria-pressed={on}
      className={`${className} ${on ? "text-liked" : ""}`}
      onClick={() => (on ? unkeep(story.path) : keep(story))}
    >
      <Bookmark size={21} fill={on ? "currentColor" : "none"} />
    </button>
  );
}

/** The foot of the page gives way to reading. */
export function Reading() {
  useEffect(() => {
    let last = scrollY;
    const move = () => {
      const end = scrollY + innerHeight > root().scrollHeight - 80;
      const down = scrollY > last + 4;
      if (Math.abs(scrollY - last) < 4) return;
      if (down && !end && scrollY > 120) root().dataset.reading = "";
      else delete root().dataset.reading;
      last = scrollY;
    };
    addEventListener("scroll", move, { passive: true });
    return () => {
      removeEventListener("scroll", move);
      delete root().dataset.reading;
    };
  }, []);
  return null;
}

/** Coverage that goes on: asks again while the page is looked at. */
export function LiveRefresh() {
  const router = useRouter();
  useEffect(() => {
    const id = setInterval(() => document.visibilityState === "visible" && router.refresh(), 30_000);
    return () => clearInterval(id);
  }, [router]);
  return null;
}

/** Never over the page, never again once closed. iPhones have Safari's own. */
export function OpenInApp({ href, text, action, close }: Record<"href" | "text" | "action" | "close", string>) {
  const [open, set] = useState(false);
  useEffect(() => {
    let closed = true;
    try {
      closed = localStorage.getItem("app-banner") === "closed";
    } catch {}
    set(!closed && /Android/.test(navigator.userAgent));
  }, []);
  if (!open) return null;
  return (
    <aside className="fixed inset-x-3 bottom-18 z-30 flex items-center gap-3 rounded-lg border border-border bg-surface-raised p-2 pl-4 shadow-lg lg:hidden">
      <Smartphone size={22} className="shrink-0" />
      <p className="min-w-0 flex-1 text-label">{text}</p>
      <a href={href} className="tap inline-flex items-center rounded-sm bg-brand px-4 text-label text-on-brand">
        {action}
      </a>
      <button
        type="button"
        aria-label={close}
        className={ICON}
        onClick={() => {
          set(false);
          remember("app-banner", "closed");
        }}
      >
        <X size={18} />
      </button>
    </aside>
  );
}

/** Saved on this device (M4 moves them into the account). */
export function SavedList({
  empty,
  remove,
  children,
}: {
  empty: React.ReactNode;
  remove: string;
  children: string;
}) {
  const [list, set] = useState<Kept[] | null>(null);
  useEffect(() => {
    const look = () => set(kept());
    look();
    return onKept(look);
  }, []);
  if (list === null) return <div className="min-h-96" role="status" aria-label={children} />;
  if (list.length === 0) return empty;
  return (
    <ul className="divide-y divide-border">
      {list.map((k) => (
        <li key={k.path} className="flex items-start gap-3 py-4">
          <a href={k.path} className="group min-w-0 flex-1">
            <span className="block truncate text-caption text-text-secondary">{k.category}</span>
            <span className="font-serif text-headline-s group-hover:underline">{k.headline}</span>
          </a>
          <button type="button" aria-label={`${remove}: ${k.headline}`} className={ICON} onClick={() => unkeep(k.path)}>
            <X size={18} />
          </button>
        </li>
      ))}
    </ul>
  );
}
