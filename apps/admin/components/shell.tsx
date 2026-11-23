"use client";
import { useQueryClient } from "@tanstack/react-query";
import { Command } from "cmdk";
import {
  Activity,
  BadgeCheck,
  Fingerprint,
  LayoutDashboard,
  LogOut,
  type LucideIcon,
  Menu,
  Moon,
  Plug,
  ScrollText,
  Search,
  Settings,
  ShieldCheck,
  Sun,
  Users,
  X,
} from "lucide-react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useLocale, useTranslations } from "next-intl";
import { Dialog as RadixDialog } from "radix-ui";
import { type ReactNode, useCallback, useEffect, useRef, useState } from "react";
import { call, client, onStepUp, onUnauthenticated, setCsrf } from "@/lib/api";
import { useSession } from "@/lib/queries";
import { MfaChallenge } from "./mfa";
import { Bone, Button, cx, Dialog, ErrorState } from "./ui";

type Item = { href: string; key: string; icon: LucideIcon; perm?: string };
export const NAV: Item[] = [
  { href: "/", key: "dashboard", icon: LayoutDashboard },
  { href: "/integrations", key: "integrations", icon: Plug, perm: "integrations.view" },
  { href: "/approvals", key: "approvals", icon: BadgeCheck, perm: "approvals.decide" },
  { href: "/staff", key: "staff", icon: Users, perm: "staff.view" },
  { href: "/roles", key: "roles", icon: ShieldCheck, perm: "staff.view" },
  { href: "/audit", key: "audit", icon: ScrollText, perm: "audit.view" },
  { href: "/logs", key: "logs", icon: Activity, perm: "audit.view" },
  { href: "/settings", key: "settings", icon: Settings, perm: "settings.view" },
  { href: "/security", key: "security", icon: Fingerprint },
];

const setCookie = (name: string, value: string) => {
  // biome-ignore lint/suspicious/noDocumentCookie: a display preference, read by the server before first paint
  document.cookie = `${name}=${value}; path=/; max-age=31536000; samesite=lax`;
};

function Palette({ items, open, setOpen }: { items: Item[]; open: boolean; setOpen: (v: boolean) => void }) {
  const t = useTranslations("nav");
  const c = useTranslations("common");
  const router = useRouter();
  return (
    <RadixDialog.Root open={open} onOpenChange={setOpen}>
      <RadixDialog.Portal>
        <RadixDialog.Overlay className="fixed inset-0 z-40 bg-black/50" />
        <RadixDialog.Content
          aria-describedby={undefined}
          className="fixed inset-x-4 top-24 z-50 mx-auto max-w-lg overflow-hidden rounded-lg border border-border bg-surface-raised"
        >
          <RadixDialog.Title className="sr-only">{c("commands")}</RadixDialog.Title>
          <Command label={c("commands")}>
            <Command.Input
              placeholder={c("searchCommands")}
              className="w-full border-b border-border bg-transparent px-4 py-4 outline-none"
            />
            <Command.List className="max-h-80 overflow-y-auto p-2">
              <Command.Empty className="p-4 text-text-secondary">{c("noResults")}</Command.Empty>
              {items.map(({ href, key, icon: Icon }) => (
                <Command.Item
                  key={href}
                  value={t(key as never)}
                  onSelect={() => {
                    setOpen(false);
                    router.push(href);
                  }}
                  className="tap flex cursor-pointer items-center gap-3 rounded-sm px-3 data-[selected=true]:bg-accent-soft data-[selected=true]:text-accent"
                >
                  <Icon aria-hidden size={18} />
                  {t(key as never)}
                </Command.Item>
              ))}
            </Command.List>
          </Command>
        </RadixDialog.Content>
      </RadixDialog.Portal>
    </RadixDialog.Root>
  );
}

export function Shell({ children }: { children: ReactNode }) {
  const t = useTranslations("nav");
  const c = useTranslations("common");
  const m = useTranslations("mfa");
  const locale = useLocale();
  const path = usePathname();
  const router = useRouter();
  const queries = useQueryClient();
  const { data: session, error, refetch } = useSession();
  const [menu, setMenu] = useState(false);
  const [palette, setPalette] = useState(false);
  const [asking, setAsking] = useState(false);
  const answer = useRef<((ok: boolean) => void) | null>(null);

  const toLogin = useCallback(
    () => location.assign(`/login?next=${encodeURIComponent(location.pathname)}`),
    [],
  );
  useEffect(() => {
    if (!session) return;
    setCsrf(session.csrf_token);
    if (session.stage !== "active") toLogin();
  }, [session, toLogin]);
  useEffect(() => {
    onUnauthenticated(toLogin);
    onStepUp(
      () =>
        new Promise((resolve) => {
          answer.current = resolve;
          setAsking(true);
        }),
    );
    const onKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setPalette((v) => !v);
      }
    };
    addEventListener("keydown", onKey);
    return () => {
      removeEventListener("keydown", onKey);
      onStepUp(null);
      onUnauthenticated(null);
    };
  }, [toLogin]);
  const settle = (ok: boolean) => {
    setAsking(false);
    answer.current?.(ok);
    answer.current = null;
  };
  const logout = async () => {
    await call(() => client.DELETE("/api/v1/auth/session")).catch(() => undefined);
    queries.clear();
    location.assign("/login");
  };
  const toggleTheme = () => {
    const root = document.documentElement;
    const dark = root.dataset.theme
      ? root.dataset.theme === "dark"
      : matchMedia("(prefers-color-scheme: dark)").matches;
    root.dataset.theme = dark ? "light" : "dark";
    setCookie("theme", root.dataset.theme);
  };

  const ready = session?.stage === "active";
  const items = NAV.filter((i) => !i.perm || session?.permissions.includes(i.perm));
  return (
    <div className="lg:grid lg:min-h-dvh lg:grid-cols-[248px_minmax(0,1fr)]">
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:fixed focus:top-2 focus:left-2 focus:z-50 focus:rounded-sm focus:bg-surface focus:p-3"
      >
        {c("skip")}
      </a>
      <aside
        className={cx(
          "border-border bg-surface lg:sticky lg:top-0 lg:flex lg:h-dvh lg:flex-col lg:border-r",
          menu ? "fixed inset-0 z-30 flex flex-col" : "hidden",
        )}
      >
        <div className="flex items-center justify-between px-5 py-4">
          <span className="font-serif text-headline-s">
            {session?.brand_name ?? <Bone className="w-24" />}
          </span>
          <button
            type="button"
            aria-label={c("close")}
            onClick={() => setMenu(false)}
            className="tap grid w-11 place-items-center rounded-sm lg:hidden"
          >
            <X aria-hidden size={20} />
          </button>
        </div>
        <nav aria-label={c("mainNav")} className="flex-1 overflow-y-auto px-3">
          <ul className="flex flex-col gap-1">
            {(ready ? items : NAV).map(({ href, key, icon: Icon }) => {
              const active = href === "/" ? path === "/" : path.startsWith(href);
              return (
                <li key={href}>
                  <Link
                    href={href}
                    prefetch={false}
                    aria-current={active ? "page" : undefined}
                    onClick={() => setMenu(false)}
                    className={cx(
                      "tap flex items-center gap-3 rounded-sm px-3 text-label",
                      active
                        ? "bg-accent-soft text-accent"
                        : "text-text-secondary hover:bg-surface-sunken hover:text-text-primary",
                    )}
                  >
                    <Icon aria-hidden size={18} />
                    {ready ? t(key as never) : <Bone className="w-28" />}
                  </Link>
                </li>
              );
            })}
          </ul>
        </nav>
        <div className="border-t border-border p-3">
          <p className="truncate px-3 py-2 text-caption text-text-secondary">
            {ready ? session.user.email : <Bone className="w-40" />}
          </p>
          <Button variant="ghost" onClick={logout} className="w-full justify-start">
            <LogOut aria-hidden size={18} />
            {t("signOut")}
          </Button>
        </div>
      </aside>
      <div className="min-w-0">
        <header className="flex items-center gap-2 border-b border-border bg-surface px-4 py-2">
          <button
            type="button"
            aria-label={c("menu")}
            onClick={() => setMenu(true)}
            className="tap grid w-11 place-items-center rounded-sm lg:hidden"
          >
            <Menu aria-hidden size={20} />
          </button>
          <button
            type="button"
            onClick={() => setPalette(true)}
            className="tap flex flex-1 items-center gap-2 rounded-sm px-3 text-left text-label text-text-secondary hover:bg-surface-sunken sm:max-w-xs"
          >
            <Search aria-hidden size={18} /> {c("searchCommands")}
            <kbd className="ml-auto hidden font-sans text-caption sm:inline">⌘K</kbd>
          </button>
          <div className="ml-auto flex">
            <Button
              variant="ghost"
              onClick={() => {
                setCookie("locale", locale === "sw" ? "en" : "sw");
                router.refresh();
              }}
              aria-label={c("switchLanguage")}
            >
              {locale === "sw" ? "EN" : "SW"}
            </Button>
            <Button variant="ghost" onClick={toggleTheme} aria-label={c("toggleTheme")} className="px-3">
              <Sun aria-hidden size={18} className="dark-only" />
              <Moon aria-hidden size={18} className="light-only" />
            </Button>
          </div>
        </header>
        <main id="main" className="mx-auto w-full max-w-6xl px-4 py-8 sm:px-8">
          {error && !session ? <ErrorState error={error} retry={() => refetch()} /> : children}
        </main>
      </div>
      <Palette items={items} open={palette} setOpen={setPalette} />
      <Dialog
        open={asking}
        onClose={() => settle(false)}
        title={m("stepUpTitle")}
        description={m("stepUpLead")}
      >
        {session && <MfaChallenge methods={session.mfa_methods} onDone={() => settle(true)} />}
      </Dialog>
    </div>
  );
}
