import { watch } from "@/lib/early-errors";

// Runs before the app. Trusted Types blocks every string-to-DOM sink; the one exception is loading our own
// bundles. There is deliberately no createHTML or createScript, so those sinks stay blocked.
type Factory = {
  createPolicy: (name: string, rules: { createScriptURL: (url: string) => string }) => unknown;
};
const factory = (globalThis as unknown as { trustedTypes?: Factory }).trustedTypes;
if (factory) {
  try {
    factory.createPolicy("default", {
      createScriptURL(raw) {
        const url = new URL(raw, location.origin);
        if (url.origin === location.origin && url.pathname.startsWith("/_next/static/")) return raw;
        throw new TypeError("Blocked script URL");
      },
    });
  } catch {
    // Already installed (fast refresh).
  }
}
watch();
