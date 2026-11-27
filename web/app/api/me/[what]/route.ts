import { asReader, json } from "@/lib/reader";

const LISTS = new Set(["saved", "liked", "follows", "export"]);

export async function GET(request: Request, { params }: { params: Promise<{ what: string }> }) {
  const { what } = await params;
  if (!LISTS.has(what)) return json({ code: "not_found" }, 404);
  const locale = new URL(request.url).searchParams.get("locale") === "en" ? "en" : "sw";
  const { status, body } = await asReader(what === "export" ? "me/export" : `me/${what}?locale=${locale}`);
  if (what === "export" && status === 200)
    return new Response(JSON.stringify(body, null, 2), {
      headers: {
        "content-type": "application/json",
        "content-disposition": 'attachment; filename="my-data.json"',
        "cache-control": "no-store",
      },
    });
  return json(body, status);
}
