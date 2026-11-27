import { anonymous } from "@/lib/reader";

/** Which ways of signing in are open: the same for everyone, kept a minute. */
export async function GET() {
  const { status, body } = await anonymous("auth/methods");
  return Response.json(body, { status, headers: { "cache-control": "public, max-age=60, s-maxage=60" } });
}
