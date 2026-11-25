import "server-only";
import { notFound, permanentRedirect } from "next/navigation";
import { moved } from "./api";

/** An address nothing answers to: where it lives now, for ever, or the page that says it is not here. */
export async function goneOrMoved(path: string): Promise<never> {
  const to = await moved(path);
  if (to) permanentRedirect(to);
  notFound();
}
