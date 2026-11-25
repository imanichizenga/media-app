/** How long the CDN keeps an anonymous page. Browsers always ask; the CDN answers, and refreshes behind the reader. */
export const PUBLIC = "public, max-age=0, s-maxage=60, stale-while-revalidate=600, stale-if-error=86400";
export const XML = {
  "content-type": "application/xml; charset=utf-8",
  "cache-control": "public, max-age=60, s-maxage=300, stale-while-revalidate=600, stale-if-error=86400",
};
