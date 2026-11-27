import { env } from "@/lib/env";
import { finish, land } from "@/lib/oauth";

export async function GET(request: Request) {
  const query = new URL(request.url).searchParams;
  const flow = await finish(query.get("state"));
  const code = query.get("code");
  if (!flow || !code) return Response.redirect(new URL(`${flow?.next ?? "/"}#sign-in-failed`, env.site), 303);
  return land("google", { code, code_verifier: flow.verifier, nonce: flow.nonce }, flow.next);
}
