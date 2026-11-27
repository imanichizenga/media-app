import { anonymous, json, refuse, sameSite } from "@/lib/reader";

/** An SMS code to a phone. The API counts and limits; the reader's address goes to it signed (lib/reader.ts). */
export async function POST(request: Request) {
  if (!(await sameSite(request))) return refuse();
  const { phone, locale } = (await request.json().catch(() => ({}))) as { phone?: string; locale?: string };
  const { status, body } = await anonymous("auth/code", {
    method: "POST",
    body: JSON.stringify({ phone: String(phone ?? "").slice(0, 32), locale }),
  });
  return json(body, status);
}
