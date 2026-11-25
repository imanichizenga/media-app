import { readdirSync, readFileSync } from "node:fs";
import { ArticleBody } from "@news/ui/content";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { contentOf, viewOf } from "@/lib/view";
import { site } from "./data";

const dir = new URL("../../support/docs/content-fixtures/valid/", import.meta.url);
const files = readdirSync(dir).filter((f) => f.endsWith(".json"));

/** The renderer passes every content fixture, in the site's own context (the pictures are the ui package's test). */
describe("every content fixture", () => {
  it("is there", () => expect(files.length).toBeGreaterThan(5));
  for (const locale of ["sw", "en"] as const)
    it.each(files)(`renders in ${locale}: %s`, (file) => {
      const document = JSON.parse(readFileSync(new URL(file, dir), "utf8"));
      const html = renderToStaticMarkup(
        <ArticleBody
          document={document.document ?? document}
          context={contentOf({ assets: {} }, viewOf(locale, site))}
        />,
      );
      expect(html.length).toBeGreaterThan(40);
      expect(html).not.toMatch(/undefined|\[object|NaN|on\w+="/);
    });
});
