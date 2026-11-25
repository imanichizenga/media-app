import "server-only";

const production = process.env.NODE_ENV === "production";
/** What the site cannot run without. In production an absent value stops it; nothing is made up. */
function need(name: string, local: string): string {
  const value = process.env[name];
  if (value) return value.replace(/\/$/, "");
  if (production && process.env.NEXT_PHASE !== "phase-production-build" && !process.env.WEB_LOCAL)
    throw new Error(`${name} is not set`);
  return local;
}
export const env = {
  get api() {
    return need("API_BASE_URL", "http://127.0.0.1:8010");
  },
  /** Readers' own address of the site: canonical links and sitemaps. */
  get site() {
    return need("SITE_URL", "http://localhost:3000");
  },
  get revalidateSecret() {
    return need("REVALIDATE_SECRET", "local-dev-only-local-dev-only-local");
  },
  get redis() {
    return need("REDIS_URL", "redis://127.0.0.1:6379/7");
  },
  /** Stops a closed environment from being indexed. */
  get closed() {
    return process.env.SITE_CLOSED === "1";
  },
};
