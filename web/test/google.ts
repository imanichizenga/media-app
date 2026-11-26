/**
 * Google's required and recommended properties for the rich results this site asks for, as Google Search Central
 * documents them (read 2026-11-26: article, video, breadcrumb, profile-page, organization). The schema validator
 * (schema.ts) says the markup is well-formed; this says it is complete for Google. A required field missing is an
 * error; a recommended one missing is also an error here, unless it is listed in NOT_OURS with the reason.
 */
type Fields = { required: string[]; recommended: string[] };

export const GOOGLE: Record<string, Fields> = {
  // Article: "There are no required properties."
  NewsArticle: {
    required: [],
    recommended: [
      "author",
      "author.name",
      "author.url",
      "dateModified",
      "datePublished",
      "headline",
      "image",
    ],
  },
  // Not on Google's Article page; a BlogPosting, so held to the Article fields, plus its coverage time.
  LiveBlogPosting: {
    required: ["coverageStartTime"],
    recommended: [
      "author",
      "author.name",
      "author.url",
      "dateModified",
      "datePublished",
      "headline",
      "image",
    ],
  },
  VideoObject: {
    required: ["name", "thumbnailUrl", "uploadDate"],
    recommended: ["contentUrl|embedUrl", "description", "duration"],
  },
  BreadcrumbList: { required: ["itemListElement"], recommended: [] },
  ListItem: { required: ["position", "name"], recommended: ["item"] },
  ProfilePage: {
    required: ["mainEntity", "mainEntity.name"],
    recommended: ["mainEntity.description", "mainEntity.image"],
  },
  NewsMediaOrganization: { required: [], recommended: ["name", "url", "logo", "description"] },
};

/**
 * Recommended fields we do not give, each for a reason: a placeholder would be worse than nothing.
 *   ProfilePage mainEntity.image: a journalist without a photograph has none (Google: no placeholder images).
 *   ProfilePage mainEntity.description: a journalist without a biography has none.
 *   NewsMediaOrganization logo: below.
 */
export const NOT_OURS: Record<string, string[]> = {
  ProfilePage: ["mainEntity.image", "mainEntity.description"],
  //   NewsMediaOrganization logo: none until the client uploads the real logos in the admin (G6). The unit test
  //   (strict) proves that a brand with a logo gives it.
  NewsMediaOrganization: ["logo"],
};

const at = (o: unknown, path: string): unknown =>
  path.split(".").reduce<unknown>((v, k) => {
    const x = Array.isArray(v) ? v[0] : v;
    return x && typeof x === "object" ? (x as Record<string, unknown>)[k] : undefined;
  }, o);
const present = (o: unknown, path: string) =>
  path.split("|").some((p) => {
    const v = at(o, p);
    return v !== undefined && v !== null && v !== "" && !(Array.isArray(v) && v.length === 0);
  });

/** What an item lacks of Google's fields, by kind; nested ListItems are checked too. */
export function missing(item: Record<string, unknown>, strict = true): string[] {
  const type = String(item["@type"]);
  const fields = GOOGLE[type];
  const out: string[] = [];
  if (fields) {
    const excused = strict ? [] : (NOT_OURS[type] ?? []);
    for (const f of fields.required) if (!present(item, f)) out.push(`${type}: required ${f}`);
    for (const f of fields.recommended)
      if (!present(item, f) && !excused.includes(f)) out.push(`${type}: recommended ${f}`);
  }
  if (type === "BreadcrumbList") {
    const list = (item.itemListElement as Record<string, unknown>[]) ?? [];
    if (list.length < 2) out.push("BreadcrumbList: at least two items");
    list.forEach((li, i) => {
      for (const f of GOOGLE.ListItem?.required ?? []) if (!present(li, f)) out.push(`ListItem ${i}: ${f}`);
      if (i < list.length - 1 && !present(li, "item")) out.push(`ListItem ${i}: item`);
      if (li.position !== i + 1) out.push(`ListItem ${i}: position ${String(li.position)}`);
    });
  }
  return out;
}
