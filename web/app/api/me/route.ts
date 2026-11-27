import { cookies } from "next/headers";
import { asReader, forget, json, refuse, sameSite, signedIn } from "@/lib/reader";

/** Who is signed in, or 204 for a guest (so guests' pages never wait on the API). */
export async function GET() {
  if (!(await signedIn())) return json(null, 204);
  const { status, body } = await asReader("me");
  return json(body, status);
}
export async function PATCH(request: Request) {
  if (!(await sameSite(request))) return refuse();
  const { status, body } = await asReader("me", { method: "PATCH", body: await request.text() });
  return json(body, status);
}
export async function DELETE(request: Request) {
  if (!(await sameSite(request))) return refuse();
  const { status, body } = await asReader("me", {
    method: "DELETE",
    body: JSON.stringify({ confirm: "delete" }),
  });
  if (status === 202) forget(await cookies());
  return json(body, status);
}
