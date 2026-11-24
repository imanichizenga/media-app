import { forward } from "@/lib/tunnel";

export async function POST(request: Request) {
  return new Response(null, { status: await forward(request, process.env.SENTRY_DSN) });
}
