import { env } from "@/lib/env";
import { begin, methods, redirectUri } from "@/lib/oauth";

// Sign in with Apple's authorize endpoint; asking for name and email requires response_mode=form_post.
const AUTHORIZE = "https://appleid.apple.com/auth/authorize";

export async function GET(request: Request) {
  const { apple_services_id } = await methods();
  if (!apple_services_id) return Response.redirect(new URL("/#sign-in-failed", env.site), 303);
  const flow = await begin(new URL(request.url).searchParams.get("next") ?? "/", true);
  const url = new URL(AUTHORIZE);
  url.search = new URLSearchParams({
    client_id: apple_services_id,
    redirect_uri: redirectUri("apple"),
    response_type: "code",
    response_mode: "form_post",
    scope: "name email",
    state: flow.state,
    nonce: flow.nonce,
  }).toString();
  return Response.redirect(url, 303);
}
