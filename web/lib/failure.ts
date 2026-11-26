import "server-only";
import { site } from "./api";
import { failurePage } from "./failure-page";

/** When a page cannot be made: designed, in the reader's language, in the theme if it is known, and needing nothing. */
export async function failure(path: string): Promise<string> {
  const brand = await site().then(
    (s) => ({ name: s.identity.brand_name, css: s.theme.css }),
    () => null,
  );
  return failurePage(path, brand);
}
