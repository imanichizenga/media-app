/**
 * What a browser says the policy refused, reduced to what helps and nothing that identifies a reader: the page, the
 * directive, what was blocked (its origin, or "inline" / "eval"), the file and line. Both formats are read: the old
 * `application/csp-report` and the Reporting API's `application/reports+json`.
 */
export type Violation = {
  page: string;
  directive: string;
  blocked: string;
  source: string;
  line: number | null;
  disposition: string;
};

const MAX = 8_192;
const text = (v: unknown, n = 200) => (typeof v === "string" ? v.slice(0, n) : "");
const where = (v: unknown) => {
  const s = text(v, 500);
  if (
    !s ||
    ["inline", "eval", "self", "data", "blob", "trusted-types-policy", "trusted-types-sink"].includes(s)
  )
    return s;
  try {
    const url = new URL(s);
    return url.origin + url.pathname; // never the query: it may carry a reader's data
  } catch {
    return s.slice(0, 100);
  }
};

function one(r: Record<string, unknown>): Violation | null {
  const directive = text(r["effective-directive"] ?? r.effectiveDirective ?? r["violated-directive"], 60);
  if (!directive) return null;
  const line = r["line-number"] ?? r.lineNumber;
  return {
    page: where(r["document-uri"] ?? r.documentURL),
    directive,
    blocked: where(r["blocked-uri"] ?? r.blockedURL),
    source: where(r["source-file"] ?? r.sourceFile),
    line: typeof line === "number" ? line : null,
    disposition: text(r.disposition, 10) || "enforce",
  };
}

/** The violations in a report body, at most ten; none if it is not a report. */
export function violations(body: string): Violation[] {
  if (body.length > MAX) return [];
  let data: unknown;
  try {
    data = JSON.parse(body);
  } catch {
    return [];
  }
  const raw = Array.isArray(data)
    ? data.filter((x) => x?.type === "csp-violation").map((x) => x.body)
    : [(data as Record<string, unknown>)?.["csp-report"]];
  return raw
    .filter((r): r is Record<string, unknown> => typeof r === "object" && r !== null)
    .map(one)
    .filter((v): v is Violation => v !== null)
    .slice(0, 10);
}
