import { createHmac } from "node:crypto";

/** Says a request comes from this site itself. The same on every instance, unknown outside. */
export const internalToken = (secret: string) =>
  createHmac("sha256", secret).update("internal document").digest("hex");
