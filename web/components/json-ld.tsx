import { json } from "@/lib/seo";

/** Data, not script: nothing runs it. */
export const JsonLd = ({ data }: { data: object }) => (
  // biome-ignore lint/security/noDangerouslySetInnerHtml: our own JSON, with every "<" escaped
  <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: json(data) }} />
);
