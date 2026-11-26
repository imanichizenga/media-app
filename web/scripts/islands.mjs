// Bundles web/islands into public/js, with the content in the name, and says where in generated/islands.json.
import { mkdirSync, rmSync, writeFileSync } from "node:fs";
import { build } from "esbuild";

const root = new URL("..", import.meta.url).pathname;
rmSync(`${root}public/js`, { recursive: true, force: true });
mkdirSync(`${root}generated`, { recursive: true });
const result = await build({
  entryPoints: [`${root}islands/site.ts`],
  outdir: `${root}public/js`,
  entryNames: "[name]-[hash]",
  chunkNames: "[name]-[hash]",
  bundle: true,
  splitting: true,
  format: "esm",
  target: ["chrome100", "safari15.4", "firefox100"],
  minify: true,
  metafile: true,
  legalComments: "none",
});
const entry = Object.entries(result.metafile.outputs).find(([, o]) =>
  o.entryPoint?.endsWith("islands/site.ts"),
);
const file = entry[0].split("/").pop();
// The early script is classic and alone: it runs before the stylesheet's first paint, and imports nothing.
const early = await build({
  entryPoints: [`${root}islands/early.ts`],
  outdir: `${root}public/js`,
  entryNames: "[name]-[hash]",
  bundle: true,
  format: "iife",
  target: ["chrome100", "safari15.4", "firefox100"],
  minify: true,
  metafile: true,
  legalComments: "none",
});
const earlyFile = Object.keys(early.metafile.outputs)[0].split("/").pop();
writeFileSync(
  `${root}generated/islands.json`,
  `${JSON.stringify({ site: `/js/${file}`, early: `/js/${earlyFile}` })}\n`,
);
