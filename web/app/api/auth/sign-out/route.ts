import { cookies } from "next/headers";
import { anonymous, forget, json, refreshToken, refuse, sameSite } from "@/lib/reader";

export async function POST(request: Request) {
  if (!(await sameSite(request))) return refuse();
  const refresh = await refreshToken();
  if (refresh) await anonymous("auth/sign-out", { method: "POST", body: JSON.stringify({ refresh }) });
  forget(await cookies());
  return json(null, 204);
}
