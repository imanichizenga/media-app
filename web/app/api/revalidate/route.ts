import { pathTag } from "@/lib/api";
import { env } from "@/lib/env";
import { messageOf, verify } from "@/lib/signature";
import { firstTime, forget } from "@/lib/store";

const answer = (status: number, body: object) =>
  Response.json(body, { status, headers: { "cache-control": "no-store" } });

/** The newsroom says what changed (signed, five minutes, once). The next reader gets the new page. */
export async function POST(request: Request) {
  const body = await request.text();
  if (body.length > 200_000) return answer(413, { error: "too_large" });
  const { headers } = request;
  if (
    !verify(env.revalidateSecret, {
      timestamp: headers.get("x-timestamp"),
      signature: headers.get("x-signature"),
      body,
    })
  )
    return answer(401, { error: "signature" });
  const message = messageOf(body);
  if (!message) return answer(400, { error: "message" });
  try {
    if (!(await firstTime(message.id))) return answer(409, { error: "used" });
    const tags = new Set([...message.tags, ...message.paths.map(pathTag)]);
    // At once, on every instance: what is withdrawn must not be shown even one more time.
    await forget([...tags]);
    return answer(200, { revalidated: tags.size });
  } catch {
    return answer(503, { error: "unavailable" });
  }
}
