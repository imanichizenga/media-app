"use client";

import type { HTMLAttributes, ReactNode } from "react";

/**
 * A row the islands copy (template[data-…]). The browser puts what a template holds in its .content, out of the
 * page, so React would find it empty and, under `next dev`, render the whole page again. The rows are written on
 * the server only; in the browser React expects the empty template it finds. Readers get no framework client
 * (lib/slim.ts), so for them this is only the HTML.
 */
export function Template({
  children,
  ...attrs
}: HTMLAttributes<HTMLTemplateElement> & { children: ReactNode } & Record<
    `data-${string}`,
    string | boolean
  >) {
  return <template {...attrs}>{typeof window === "undefined" ? children : null}</template>;
}
