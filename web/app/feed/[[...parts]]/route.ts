import { feedResponse } from "@/lib/feeds";

export const dynamic = "force-dynamic";
export async function GET(_: Request, { params }: { params: Promise<{ parts?: string[] }> }) {
  return feedResponse("feed", (await params).parts);
}
