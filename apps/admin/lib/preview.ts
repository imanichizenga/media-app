import type { Logo } from "@news/ui/news";

/** What the Appearance page tells a preview frame. Same origin only, both ways. */
export const PREVIEW_SCREENS = ["home", "article", "shorts", "auth", "breaking"] as const;
export type PreviewScreen = (typeof PREVIEW_SCREENS)[number];
export type PreviewState = {
  kind: "preview";
  screen: PreviewScreen;
  scheme: "light" | "dark";
  locale: "sw" | "en";
  variables: Record<string, string>;
  brand: { name: string; light: Logo | null; dark: Logo | null };
};
export const READY = "preview-ready";
