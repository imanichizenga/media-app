import { site } from "@/lib/api";

/** The key file IndexNow asks for, at /<key>.txt; only the published key answers. */
export async function GET(request: Request) {
  const key = new URL(request.url).searchParams.get("key");
  const { seo } = await site();
  if (!key || key !== seo.indexnow_key) return new Response("Not found", { status: 404 });
  return new Response(key, {
    headers: { "content-type": "text/plain", "cache-control": "public, max-age=300" },
  });
}
