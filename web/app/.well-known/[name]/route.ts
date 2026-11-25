import { env } from "@/lib/env";

export const dynamic = "force-dynamic";
const NAMES = ["assetlinks.json", "apple-app-site-association"];

/** The site's own proof that the app may open its addresses. The ids come from the admin's app settings. */
export async function GET(_: Request, { params }: { params: Promise<{ name: string }> }) {
  const { name } = await params;
  if (!NAMES.includes(name)) return new Response("Not found", { status: 404 });
  try {
    const res = await fetch(`${env.api}/.well-known/${name}`, {
      next: { revalidate: 300, tags: ["app-config"] },
      signal: AbortSignal.timeout(5000),
    });
    if (!res.ok) throw new Error(String(res.status));
    return Response.json(await res.json(), {
      headers: { "cache-control": "public, max-age=300, s-maxage=3600" },
    });
  } catch {
    return new Response("Unavailable", { status: 503, headers: { "cache-control": "no-store" } });
  }
}
