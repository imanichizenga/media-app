import { expect, it, vi } from "vitest";

it("never asks for eval, not even to see whether it may", async () => {
  const asked = vi.fn();
  vi.stubGlobal(
    "Function",
    new Proxy(Function, {
      construct: (target, args) => {
        asked(args);
        return Reflect.construct(target, args);
      },
    }),
  );
  const { validateDocument } = await import("../src");
  expect(validateDocument({ version: 1, blocks: [] }).ok).toBe(true);
  expect(asked).not.toHaveBeenCalled();
});
