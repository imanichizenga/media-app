import { cookies } from "next/headers";
import { anonymous, json, keep, type Pair, refuse, sameSite } from "@/lib/reader";

/** The code typed: signed in. The tokens go to httpOnly cookies; the page is told only who. */
export async function POST(request: Request) {
  if (!(await sameSite(request))) return refuse();
  const { challenge, code } = (await request.json().catch(() => ({}))) as {
    challenge?: string;
    code?: string;
  };
  const { status, body } = await anonymous("auth/code/verify", {
    method: "POST",
    body: JSON.stringify({
      challenge: String(challenge ?? ""),
      code: String(code ?? "").slice(0, 12),
      device: "web",
    }),
  });
  if (status !== 200) return json(body, status);
  const done = body as Pair & { user: unknown; created: boolean };
  keep(await cookies(), done);
  return json({ user: done.user, created: done.created });
}
