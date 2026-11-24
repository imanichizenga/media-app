/** Errors thrown before the reporter has loaded. Bounded, and drained once. */
let waiting: unknown[] | null = [];
const keep = (error: unknown) => {
  if (waiting && waiting.length < 10 && error) waiting.push(error);
};
const onError = (e: ErrorEvent) => keep(e.error);
const onRejection = (e: PromiseRejectionEvent) => keep(e.reason);

export function watch() {
  addEventListener("error", onError);
  addEventListener("unhandledrejection", onRejection);
}
export function drain(): unknown[] {
  removeEventListener("error", onError);
  removeEventListener("unhandledrejection", onRejection);
  const found = waiting ?? [];
  waiting = null;
  return found;
}
