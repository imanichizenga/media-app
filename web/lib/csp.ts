import { createHash } from "node:crypto";
import { STYLE } from "./failure-style";

const originOf = (value: string | undefined) => {
  try {
    const url = new URL(value ?? "");
    return ["https:", "http:"].includes(url.protocol) ? url.origin : "";
  } catch {
    return "";
  }
};
const allow = (...sources: string[]) => sources.filter(Boolean).join(" ");
const hash = (text: string) => `'sha256-${createHash("sha256").update(text).digest("base64")}'`;

/** Where browsers send what the policy refused (POST, logged by app/api/csp-report). */
export const REPORTS = "/api/csp-report";

/** The one Trusted Types policy: the navigation island reads our own documents (islands/navigate.ts). */
export const TRUSTED_TYPES = "navigate";

/**
 * One policy for every page, with no nonce (ADR-0046): pages are kept by the CDN and seen by many readers, so a nonce
 * in them would not be secret. Nothing inline runs: the islands and the early script are files from this origin, and
 * JSON-LD is data. The failure page's fixed style is allowed by its hash.
 */
export function policy({
  media,
  dev = false,
  local = false,
}: {
  media?: string;
  dev?: boolean;
  local?: boolean;
} = {}): string {
  const files = originOf(media);
  return [
    "default-src 'none'",
    // `next dev` sends its own runtime inline; a production page has no inline script at all.
    `script-src 'self'${dev ? " 'unsafe-inline' 'unsafe-eval'" : ""}`,
    `style-src 'self' ${dev ? "'unsafe-inline'" : hash(STYLE)}`,
    // A picture's own colour and focal point are style attributes; they can run nothing.
    "style-src-attr 'unsafe-inline'",
    `img-src ${allow("'self'", "data:", files, "https://i.ytimg.com")}`,
    `media-src ${allow("'self'", "blob:", files)}`,
    "font-src 'self'",
    `connect-src ${allow("'self'", files)}`,
    "frame-src https://www.youtube-nocookie.com",
    "manifest-src 'self'",
    "worker-src 'none'",
    "object-src 'none'",
    "base-uri 'none'",
    "form-action 'self'",
    "frame-ancestors 'none'",
    ...(dev ? [] : ["require-trusted-types-for 'script'", `trusted-types ${TRUSTED_TYPES}`]),
    `report-uri ${REPORTS}`,
    "report-to csp",
    ...(dev || local ? [] : ["upgrade-insecure-requests"]),
  ].join("; ");
}

/** The Reporting API's name for the endpoint above (`report-to csp`). */
export const REPORTING_ENDPOINTS = `csp="${REPORTS}"`;
