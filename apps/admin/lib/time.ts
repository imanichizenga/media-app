/** The newsroom's clock, wherever the reader's laptop thinks it is. */
const parts = (at: Date, timeZone: string) => {
  const found = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  }).formatToParts(at);
  return (type: string) => found.find((p) => p.type === type)?.value ?? "";
};

/** Milliseconds the zone is ahead of UTC at that moment. */
const offset = (at: Date, timeZone: string) => {
  const p = parts(at, timeZone);
  const n = (type: string) => Number(p(type));
  const local = Date.UTC(n("year"), n("month") - 1, n("day"), n("hour"), n("minute"), n("second"));
  return local - Math.floor(at.getTime() / 1000) * 1000;
};

/** For <input type="datetime-local">. */
export function toZoned(iso: string | null | undefined, timeZone: string): string {
  if (!iso) return "";
  const p = parts(new Date(iso), timeZone);
  return `${p("year")}-${p("month")}-${p("day")}T${p("hour")}:${p("minute")}`;
}

export function fromZoned(value: string, timeZone: string): string | null {
  if (!value) return null;
  const naive = new Date(`${value}Z`);
  // Asked twice, because the first guess may fall on the other side of a clock change.
  const guess = new Date(naive.getTime() - offset(naive, timeZone));
  return new Date(naive.getTime() - offset(guess, timeZone)).toISOString();
}

/** YYYY-MM-DD in the zone. */
export const dayOf = (at: Date, timeZone: string) => toZoned(at.toISOString(), timeZone).slice(0, 10);
export const addDays = (day: string, n: number) =>
  new Date(Date.parse(`${day}T00:00:00Z`) + n * 86_400_000).toISOString().slice(0, 10);
export const mondayOf = (day: string) => addDays(day, -((new Date(`${day}T00:00:00Z`).getUTCDay() + 6) % 7));
