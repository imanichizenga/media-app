/** Text inside XML; characters XML forbids are dropped. */
export const x = (value: string) =>
  value
    // biome-ignore lint/suspicious/noControlCharactersInRegex: exactly the ones XML 1.0 refuses
    .replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f￾￿]/g, "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
export const el = (name: string, value: string | number | null | undefined) =>
  value === null || value === undefined || value === "" ? "" : `<${name}>${x(String(value))}</${name}>`;
const XMLNS = "http://www.sitemaps.org/schemas/sitemap/0.9";
const GOOGLE = "http://www.google.com/schemas";
export const SPACES = {
  news: `xmlns:news="${GOOGLE}/sitemap-news/0.9"`,
  image: `xmlns:image="${GOOGLE}/sitemap-image/1.1"`,
  video: `xmlns:video="${GOOGLE}/sitemap-video/1.1"`,
  xhtml: 'xmlns:xhtml="http://www.w3.org/1999/xhtml"',
};
export const urlset = (spaces: (keyof typeof SPACES)[], urls: string[]) =>
  `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="${XMLNS}" ${spaces.map((s) => SPACES[s]).join(" ")}>\n${urls.join("\n")}\n</urlset>\n`;
export const index = (maps: { loc: string; modified?: string }[]) =>
  `<?xml version="1.0" encoding="UTF-8"?>\n<sitemapindex xmlns="${XMLNS}">\n${maps
    .map((m) => `<sitemap>${el("loc", m.loc)}${el("lastmod", m.modified)}</sitemap>`)
    .join("\n")}\n</sitemapindex>\n`;
