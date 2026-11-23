import type { Block, ContentDocument } from "./generated/types";
import { lenient, strict } from "./generated/validators";

export * from "./generated/types";

export type UnknownBlock = { type: "unknown"; id: string; originalType: string };
export type ReadBlock = Block | UnknownBlock;
export type ReadDocument = { version: number; blocks: ReadBlock[] };

/** For readers: never throws. A block that cannot be understood becomes one the renderer can place calmly. */
export function readDocument(input: unknown): ReadDocument {
  const raw = (input ?? {}) as { version?: unknown; blocks?: unknown };
  const blocks = Array.isArray(raw.blocks) ? raw.blocks : [];
  return {
    version: typeof raw.version === "number" ? raw.version : 1,
    blocks: blocks.map((block, index): ReadBlock => {
      const parsed = lenient.block.safeParse(block);
      if (parsed.success) return parsed.data as Block;
      const { id, type } = (block ?? {}) as { id?: unknown; type?: unknown };
      return {
        type: "unknown",
        id: typeof id === "string" && id ? id : `unknown-${index}`,
        originalType: typeof type === "string" ? type : "",
      };
    }),
  };
}

export type Problem = { path: string; message: string };
/** For writers: exactly what the API accepts. */
export function validateDocument(
  input: unknown,
): { ok: true; document: ContentDocument } | { ok: false; problems: Problem[] } {
  const parsed = strict.document.safeParse(input);
  const problems = parsed.success
    ? duplicateIds(parsed.data as ContentDocument)
    : parsed.error.issues.map((i) => ({ path: i.path.join("."), message: i.message }));
  return problems.length ? { ok: false, problems } : { ok: true, document: parsed.data as ContentDocument };
}

function duplicateIds(document: ContentDocument): Problem[] {
  const seen = new Set<string>();
  const problems: Problem[] = [];
  const visit = (id: string, path: string) => {
    if (seen.has(id)) problems.push({ path, message: "duplicate id" });
    seen.add(id);
  };
  document.blocks.forEach((block, i) => {
    visit(block.id, `blocks.${i}.id`);
    if (block.type === "live_update")
      block.blocks.forEach((b, j) => {
        visit(b.id, `blocks.${i}.blocks.${j}.id`);
      });
  });
  return problems;
}
