import {
  BrowserClient,
  dedupeIntegration,
  defaultStackParser,
  type ErrorEvent,
  eventFiltersIntegration,
  getCurrentScope,
  globalHandlersIntegration,
  linkedErrorsIntegration,
  makeFetchTransport,
} from "@sentry/browser";

const SECRETS = [
  /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g,
  /\+\d{8,15}/g,
  /\b(?:AKIA|ASIA)[A-Z0-9]{16}\b/g,
  /\beyJ[\w-]{8,}\.[\w-]{8,}\.[\w-]*/g,
  /\b[\w-]{40,}\b/g, // one-time links, session and CSRF tokens
];
export const redact = (text: string) => SECRETS.reduce((s, p) => s.replace(p, "[redacted]"), text);
const path = (url: string) => url.split(/[?#]/, 1)[0] ?? "";

/** An allowlist, not a blocklist: the report is rebuilt from what debugging needs. */
export function scrub(event: ErrorEvent): ErrorEvent {
  return {
    type: undefined,
    event_id: event.event_id,
    timestamp: event.timestamp,
    platform: event.platform,
    level: event.level,
    release: event.release,
    environment: event.environment,
    sdk: event.sdk,
    message: event.message && redact(event.message),
    request: event.request?.url ? { url: path(event.request.url) } : undefined,
    exception: {
      values: event.exception?.values?.map((e) => ({
        type: e.type,
        value: e.value && redact(e.value),
        mechanism: e.mechanism && { type: e.mechanism.type, handled: e.mechanism.handled },
        stacktrace: {
          frames: e.stacktrace?.frames?.map((f) => ({
            filename: f.filename && path(f.filename),
            function: f.function,
            lineno: f.lineno,
            colno: f.colno,
            in_app: f.in_app,
          })),
        },
      })),
    },
  };
}

/** Answers the API gave on purpose are not faults, and an offline laptop is not our bug. */
export function isExpected(error: unknown): boolean {
  if (!(error instanceof Error) || !("status" in error) || typeof error.status !== "number") return false;
  return error.status < 500;
}

export function start(early: unknown[]) {
  const client = new BrowserClient({
    // The real DSN stays on the server: /monitoring adds it, so the CSP needs no third-party origin.
    dsn: "https://browser@monitoring.invalid/1",
    tunnel: "/monitoring",
    transport: makeFetchTransport,
    stackParser: defaultStackParser,
    // No breadcrumbs, sessions, tracing or replay: clicks and requests of staff are not recorded.
    integrations: [
      eventFiltersIntegration(),
      globalHandlersIntegration(),
      linkedErrorsIntegration(),
      dedupeIntegration(),
    ],
    sendClientReports: false,
    maxValueLength: 500,
    beforeSend: (event, hint) => (isExpected(hint.originalException) ? null : scrub(event)),
  });
  getCurrentScope().setClient(client);
  client.init();
  for (const error of early) client.captureException(error);
}
