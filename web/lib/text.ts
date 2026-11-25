/** The words of a body, for word counts and feeds. */
export function blocksText(document: unknown): string {
  const out: string[] = [];
  const walk = (node: unknown) => {
    if (Array.isArray(node)) node.forEach(walk);
    else if (node && typeof node === "object")
      for (const [key, value] of Object.entries(node)) {
        if (key === "text" && typeof value === "string") out.push(value);
        else if (typeof value === "object") walk(value);
      }
  };
  walk((document as { blocks?: unknown })?.blocks);
  return out.join(" ").replace(/\s+/g, " ").trim();
}
