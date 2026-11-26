import { violations } from "@/lib/violations";

const done = () => new Response(null, { status: 204, headers: { "cache-control": "no-store" } });

/**
 * Browsers report here what the policy refused (lib/csp.ts). Each violation is one line of JSON in the log, which the
 * platform's log alarms read; nothing is stored and nothing about the reader is kept.
 */
export async function POST(request: Request) {
  const length = Number(request.headers.get("content-length") ?? 0);
  if (length > 8_192) return new Response(null, { status: 413 });
  for (const v of violations(await request.text()))
    console.warn(JSON.stringify({ event: "csp_violation", ...v }));
  return done();
}
