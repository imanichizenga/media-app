// node contact-sheet.mjs <milestone> writes docs/design/screens/<milestone>/index.html: every screenshot, filterable, no dependencies.
import { readdirSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

const milestone = process.argv[2] ?? "m1";
const dir = resolve(import.meta.dirname, `../../docs/design/screens/${milestone}`);
const shots = readdirSync(dir)
  .filter((f) => f.endsWith(".jpg"))
  .sort()
  .map((file) => {
    const [screen, state, variant] = file.replace(".jpg", "").split("--");
    const [device, theme, locale] = variant.split("-");
    return { file, screen, state, device, theme, locale };
  });
const values = (key) => [...new Set(shots.map((s) => s[key]))];
const figure = (s) =>
  `<figure data-device="${s.device}" data-theme="${s.theme}" data-locale="${s.locale}" data-state="${s.state}"><a href="${s.file}"><img loading="lazy" src="${s.file}" alt="${s.screen}, ${s.state}, ${s.device}, ${s.theme}, ${s.locale}"></a><figcaption>${s.state} · ${s.device} · ${s.theme} · ${s.locale}</figcaption></figure>`;
const select = (key) =>
  `<label>${key} <select name="${key}"><option value="">all</option>${values(key)
    .map((v) => `<option>${v}</option>`)
    .join("")}</select></label>`;
writeFileSync(
  `${dir}/index.html`,
  `<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>${milestone.toUpperCase()} admin screens</title>
<style>body{font:15px system-ui;margin:24px;background:#f6f6f4;color:#1a1a1a}form{display:flex;flex-wrap:wrap;gap:16px;position:sticky;top:0;background:inherit;padding:12px 0}.row{display:flex;flex-wrap:wrap;gap:16px;align-items:flex-start}figure{margin:0}img{display:block;height:340px;border:1px solid #ccc;border-radius:8px}figcaption{font-size:12px;color:#555;padding:4px 0}[hidden]{display:none}</style>
<h1>${milestone.toUpperCase()} admin screens</h1><p>${shots.length} captures from the running console with synthetic data. Regenerate: <code>SCREENS=${milestone} pnpm --filter @news/e2e screens</code>.</p>
<form>${["device", "theme", "locale", "state"].map(select).join("")}</form>
${values("screen")
  .map(
    (name) =>
      `<h2>${name}</h2><div class="row">${shots
        .filter((s) => s.screen === name)
        .map(figure)
        .join("")}</div>`,
  )
  .join("")}
<script>const f=document.querySelector("form");f.oninput=()=>{const q=[...new FormData(f)].filter(([,v])=>v);for(const e of document.querySelectorAll("figure"))e.hidden=!q.every(([k,v])=>e.dataset[k]===v)}</script></html>
`,
);
console.log(`${shots.length} screenshots`);
