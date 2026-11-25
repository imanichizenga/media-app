import { z } from "zod";

/**
 * What Google requires and recommends of each type (developers.google.com/search/docs/appearance/structured-data).
 * Strict: a misspelled property fails. Run on fixtures here and on every real page in the end-to-end tests.
 */
const url = z.url({ protocol: /^https?$/ });
const time = z
  .string()
  .refine((v) => /T.*(Z|[+-]\d\d:\d\d)$/.test(v) && !Number.isNaN(Date.parse(v)), "ISO 8601 with a zone");
const ref = z.strictObject({ "@id": url });
const organization = z.strictObject({
  "@type": z.literal("NewsMediaOrganization"),
  "@id": url,
  name: z.string().min(1),
  url,
  logo: z
    .strictObject({
      "@type": z.literal("ImageObject"),
      url,
      width: z.number().min(112),
      height: z.number().min(1),
    })
    .optional(),
  sameAs: z.array(url).optional(),
  publishingPrinciples: url,
  correctionsPolicy: url,
});
const person = z.strictObject({
  "@type": z.literal("Person"),
  name: z.string().min(1),
  url,
  jobTitle: z.string().optional(),
  description: z.string().optional(),
  knowsAbout: z.array(z.string()).optional(),
  sameAs: z.array(url).optional(),
  image: z.array(url).optional(),
  worksFor: organization.optional(),
});
const work = {
  headline: z.string().min(1).max(110),
  description: z.string().min(1),
  // Three shapes (16:9, 4:3, 1:1); a story without a picture has none.
  image: z.array(url).refine((l) => l.length === 0 || l.length === 3),
  datePublished: time,
  dateModified: time,
  author: z.array(person).min(1),
  publisher: organization,
  mainEntityOfPage: z.strictObject({ "@type": z.literal("WebPage"), "@id": url }),
  url,
  inLanguage: z.enum(["sw", "en"]),
  articleSection: z.string().min(1),
  keywords: z.array(z.string()).optional(),
  isAccessibleForFree: z.literal(true),
  correction: z.string().optional(),
};
const item = z.discriminatedUnion("@type", [
  organization,
  z.strictObject({ "@type": z.literal("NewsArticle"), ...work, wordCount: z.number().int().min(0) }),
  z.strictObject({
    "@type": z.literal("LiveBlogPosting"),
    ...work,
    coverageStartTime: time,
    coverageEndTime: time.optional(),
    liveBlogUpdate: z
      .array(
        z.strictObject({
          "@type": z.literal("BlogPosting"),
          headline: z.string().min(1).max(110),
          datePublished: time,
          url,
          articleBody: z.string(),
        }),
      )
      .min(1),
  }),
  z
    .strictObject({
      "@type": z.literal("VideoObject"),
      name: z.string().min(1),
      description: z.string().min(1),
      thumbnailUrl: z.array(url).min(1),
      uploadDate: time,
      duration: z
        .string()
        .regex(/^PT\d+M\d+S$/)
        .optional(),
      contentUrl: url.optional(),
      embedUrl: url.optional(),
    })
    .refine((v) => v.contentUrl || v.embedUrl, "somewhere it plays"),
  z.strictObject({
    "@type": z.literal("BreadcrumbList"),
    itemListElement: z
      .array(
        z.strictObject({
          "@type": z.literal("ListItem"),
          position: z.number().int().min(1),
          name: z.string().min(1),
          item: url,
        }),
      )
      .min(2)
      .refine((l) => l.every((e, i) => e.position === i + 1)),
  }),
  z.strictObject({
    "@type": z.literal("WebSite"),
    "@id": url,
    name: z.string().min(1),
    url,
    inLanguage: z.enum(["sw", "en"]),
    publisher: ref,
  }),
  z.strictObject({ "@type": z.literal("ProfilePage"), mainEntity: person }),
]);
export const structured = z.strictObject({
  "@context": z.literal("https://schema.org"),
  "@graph": z.array(item).min(1),
});
