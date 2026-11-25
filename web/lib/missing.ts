import "server-only";
import { notFound, permanentRedirect } from "next/navigation";
import { moved } from "./api";

/** The proxy has already looked for an old address (301). This catches what moved in the same minute. */
export async function goneOrMoved(path: string, known?: string): Promise<never> {
  const to = known ?? (await moved(path));
  if (to && to !== path) permanentRedirect(to);
  notFound();
}
