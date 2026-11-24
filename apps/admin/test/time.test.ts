import { describe, expect, it } from "vitest";
import { addDays, dayOf, fromZoned, mondayOf, toZoned } from "../lib/time";

const DAR = "Africa/Dar_es_Salaam";
describe("the newsroom clock", () => {
  it("shows and reads newsroom time whatever this machine uses", () => {
    expect(toZoned("2026-11-24T21:30:00Z", DAR)).toBe("2026-11-25T00:30");
    expect(fromZoned("2026-11-25T00:30", DAR)).toBe("2026-11-24T21:30:00.000Z");
    expect(fromZoned("2026-11-25T00:30:15", DAR)).toBe("2026-11-24T21:30:15.000Z");
  });
  it.each(["2026-03-29T00:30", "2026-03-29T03:30", "2026-10-25T04:00", "2026-07-01T12:00"])(
    "survives clock changes elsewhere: %s",
    (value) => expect(toZoned(fromZoned(value, "Europe/London"), "Europe/London")).toBe(value),
  );
  it("has nothing for nothing", () => {
    expect(toZoned(null, DAR)).toBe("");
    expect(fromZoned("", DAR)).toBeNull();
  });
  it("finds days and weeks", () => {
    expect(dayOf(new Date("2026-11-24T21:30:00Z"), DAR)).toBe("2026-11-25");
    expect(mondayOf("2026-11-29")).toBe("2026-11-23");
    expect(mondayOf("2026-11-23")).toBe("2026-11-23");
    expect(addDays("2026-12-31", 1)).toBe("2027-01-01");
  });
});
