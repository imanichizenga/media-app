import { Bone } from "@news/ui/base";
import { Bell, Bookmark, Share2, Smartphone, SunMoon, X } from "@news/ui/icons";
import type { ReactNode } from "react";
import type { T } from "@/lib/i18n";

// What the reader presses. Plain elements: web/islands makes them work, and no framework is sent (ADR-0046).
const ICON = "tap grid w-11 place-items-center rounded-sm hover:bg-current/10";

/** Light, dark, and back. The choice stays in this browser. */
export const SchemeButton = ({ label }: { label: string }) => (
  <button type="button" aria-label={label} className={ICON} data-do="scheme">
    <SunMoon size={20} />
  </button>
);

/** Notifications of new stories (islands/push.ts): its words are said in a toast as things happen. */
export const NotifyButton = ({ t }: { t: T }) => {
  const say = (k: string) => t(k as never);
  return (
    <button
      type="button"
      data-do="notify"
      data-notify=""
      aria-pressed="false"
      aria-label={say("notifyTurnOn")}
      title={say("notifyTurnOn")}
      data-on={say("notifyTurnOn")}
      data-off={say("notifyTurnOff")}
      data-done={say("notifyOn")}
      data-gone={say("notifyOff")}
      data-blocked={say("notifyBlocked")}
      data-unsupported={say("notifyUnsupported")}
      className={`${ICON} notify`}
    >
      <Bell size={20} />
    </button>
  );
};

/** The same, as a row of You's settings, with a switch that shows whether it is on. */
export const NotifyRow = ({ t }: { t: T }) => {
  const say = (k: string) => t(k as never);
  return (
    <button
      type="button"
      data-do="notify"
      data-notify=""
      aria-pressed="false"
      aria-label={say("notifyTurnOn")}
      data-on={say("notifyTurnOn")}
      data-off={say("notifyTurnOff")}
      data-done={say("notifyOn")}
      data-gone={say("notifyOff")}
      data-blocked={say("notifyBlocked")}
      data-unsupported={say("notifyUnsupported")}
      className="notify tap flex min-h-13 w-full items-center gap-3 px-4 text-left hover:bg-surface-sunken"
    >
      <Bell size={20} className="text-text-secondary" />
      <span className="flex-1">{say("notifications")}</span>
      <span
        aria-hidden
        className="switch relative h-6 w-10 shrink-0 rounded-full bg-border-strong transition-colors"
      >
        <span className="absolute top-0.5 left-0.5 size-5 rounded-full bg-surface shadow-sm transition-transform" />
      </span>
    </button>
  );
};

/** The same three as the app's. */
export const SchemeChoice = ({ legend, names }: { legend: string; names: [string, string, string] }) => (
  <fieldset className="grid grid-cols-3 gap-1 rounded-md bg-surface-sunken p-1" data-schemes>
    <legend className="sr-only">{legend}</legend>
    {["", "light", "dark"].map((scheme, i) => (
      <label
        key={scheme}
        className="tap grid place-items-center rounded-sm px-2 text-center text-label has-checked:bg-bg has-checked:shadow-sm has-focus-visible:outline-2"
      >
        <input type="radio" name="scheme" value={scheme} className="sr-only" defaultChecked={scheme === ""} />
        {names[i]}
      </label>
    ))}
  </fieldset>
);

export const TextSizeChoice = ({ label, sample }: { label: string; sample: string }) => (
  <div className="flex flex-col gap-3">
    <input
      type="range"
      aria-label={label}
      min={0}
      max={3}
      defaultValue={0}
      className="tap w-full accent-brand"
      data-text-range
    />
    <p className="reads min-h-16">
      <span className="font-serif">{sample}</span>
    </p>
  </div>
);

export const ShareButton = ({
  label,
  done,
  title,
  path,
  className = ICON,
}: {
  label: string;
  done: string;
  title: string;
  /** Something else than this page. */
  path?: string;
  className?: string;
}) => (
  <button
    type="button"
    aria-label={label}
    className={className}
    data-do="share"
    data-title={title}
    data-path={path}
    data-done={done}
  >
    <Share2 size={21} />
  </button>
);

export const SaveButton = ({
  story,
  save,
  unsave,
  done,
  undone,
  className = ICON,
  on = "aria-pressed:text-liked",
}: {
  story: { path: string; headline: string; category: string; post?: string };
  save: string;
  unsave: string;
  /** Said when it is kept, and when it is let go. */
  done?: string;
  undone?: string;
  className?: string;
  on?: string;
}) => (
  <button
    type="button"
    aria-label={save}
    aria-pressed="false"
    className={`${className} ${on} aria-pressed:[&>svg]:fill-current`}
    data-do="save"
    data-path={story.path}
    data-headline={story.headline}
    data-category={story.category}
    data-post={story.post}
    data-save={save}
    data-unsave={unsave}
    data-done={done}
    data-undone={undone}
  >
    <Bookmark size={21} />
  </button>
);

/** Said once, above everything, while there is no network. */
export const Offline = ({ text, action, href }: Record<"text" | "action" | "href", string>) => (
  <div role="status" className="fixed inset-x-0 top-0 z-40">
    <p
      hidden
      data-offline
      className="flex flex-wrap items-center justify-center gap-x-4 bg-text-primary px-4 py-1 text-bg text-label [[hidden]]:hidden"
    >
      {text}
      <a href={href} className="tap inline-flex items-center underline underline-offset-4">
        {action}
      </a>
    </p>
  </div>
);

/** Never over the page, never again once closed. iPhones have Safari's own. */
export const OpenInApp = ({
  href,
  text,
  action,
  close,
}: Record<"href" | "text" | "action" | "close", string>) => (
  <aside
    hidden
    data-app-banner
    aria-label={text}
    className="fixed inset-x-3 bottom-18 z-30 flex items-center gap-3 rounded-lg border border-border bg-surface-raised p-2 pl-4 shadow-lg lg:hidden [[hidden]]:hidden"
  >
    <Smartphone size={22} className="shrink-0" />
    <p className="min-w-0 flex-1 text-label">{text}</p>
    <a href={href} className="tap inline-flex items-center rounded-sm bg-brand px-4 text-label text-on-brand">
      {action}
    </a>
    <button type="button" aria-label={close} className={ICON} data-do="close-app">
      <X size={18} />
    </button>
  </aside>
);

/** Coverage that goes on: asked again while the page is looked at, and never moved under the reader's eyes (V2). */
export const LiveRefresh = ({ label }: { label: string }) => (
  <div
    data-live
    hidden
    className="pointer-events-none fixed inset-x-0 top-16 z-30 flex justify-center [[hidden]]:hidden"
  >
    <button
      type="button"
      data-do="live"
      className="tap pointer-events-auto rounded-full bg-text-primary px-5 text-bg text-label shadow-lg"
    >
      {label}
    </button>
  </div>
);

const Row = ({ remove, bones = false }: { remove: string; bones?: boolean }) => (
  <li className="flex items-start gap-3 py-4">
    <a className="group min-w-0 flex-1" href={bones ? undefined : "#"}>
      <span className="block truncate text-caption text-text-secondary" data-category>
        {bones && <Bone className="w-24" />}
      </span>
      <span className="block font-serif text-headline-s group-hover:underline" data-headline>
        {bones && <Bone className="w-2/3" />}
      </span>
    </a>
    {!bones && (
      <button type="button" aria-label={remove} className={ICON} data-do="unsave">
        <X size={18} />
      </button>
    )}
  </li>
);
/** Saved on this device (M4 moves them into the account). */
export const SavedList = ({ empty, remove, label }: { empty: ReactNode; remove: string; label: string }) => (
  <div data-saved>
    <ul className="divide-y divide-border" aria-label={label}>
      {[1, 2, 3].map((n) => (
        <Row key={n} remove={remove} bones />
      ))}
    </ul>
    <template data-row>
      <Row remove={remove} />
    </template>
    <div hidden data-empty className="[[hidden]]:hidden">
      {empty}
    </div>
  </div>
);
