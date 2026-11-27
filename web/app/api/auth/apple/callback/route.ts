import { env } from "@/lib/env";
import { finish, land } from "@/lib/oauth";

/** Apple POSTs the result here (form_post). Its `user` field, with the name, comes only the first time. */
export async function POST(request: Request) {
  const form = await request.formData().catch(() => null);
  const flow = await finish(String(form?.get("state") ?? "") || null);
  const code = String(form?.get("code") ?? "");
  if (!flow || !code) return Response.redirect(new URL(`${flow?.next ?? "/"}#sign-in-failed`, env.site), 303);
  let name = "";
  try {
    const user = JSON.parse(String(form?.get("user") ?? "{}")) as {
      name?: { firstName?: string; lastName?: string };
    };
    name = [user.name?.firstName, user.name?.lastName].filter(Boolean).join(" ");
  } catch {
    // no name: the reader says it after signing in
  }
  return land("apple", { code, name, nonce: flow.nonce }, flow.next);
}
