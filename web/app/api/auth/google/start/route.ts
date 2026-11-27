import { env } from "@/lib/env";
import { begin, methods, redirectUri } from "@/lib/oauth";

const AUTHORIZE = "https://accounts.google.com/o/oauth2/v2/auth"; // the discovery document's authorization_endpoint

export async function GET(request: Request) {
  const { google_client_id } = await methods();
  if (!google_client_id) return Response.redirect(new URL("/#sign-in-failed", env.site), 303);
  const flow = await begin(new URL(request.url).searchParams.get("next") ?? "/", false);
  const url = new URL(AUTHORIZE);
  url.search = new URLSearchParams({
    client_id: google_client_id,
    redirect_uri: redirectUri("google"),
    response_type: "code",
    scope: "openid email profile",
    state: flow.state,
    nonce: flow.nonce,
    code_challenge: flow.challenge,
    code_challenge_method: "S256",
    prompt: "select_account",
  }).toString();
  return Response.redirect(url, 303);
}
