import { describe, expect, test } from "vitest";
import { clock, compact, exact, seconds } from "../src/news";

describe("numbers", () => {
  test.each([
    [0, "0"],
    [999, "999"],
    [1284, "1.3K"],
    [12_480, "12.5K"],
    [999_950, "1M"],
    [3_400_000, "3.4M"],
    [1_200_000_000, "1.2B"],
  ])("%d is %s in both languages", (n, text) => {
    expect(compact(n, "sw")).toBe(text);
    expect(compact(n, "en")).toBe(text);
  });
  test("the whole number is said aloud", () => {
    expect(exact(1284, "en")).toBe("1,284");
    expect(exact(1284, "sw")).toBe("1,284");
  });
  test.each([
    [8_000, "0:08"],
    [750_000, "12:30"],
    [3_725_000, "1:02:05"],
  ])("%d ms is %s", (ms, text) => {
    expect(clock(ms)).toBe(text);
    expect(seconds(text) * 1000).toBe(ms);
  });
  test.each(["", "abc", "1:2:3:4", "-5"])("%s is no length", (text) => expect(seconds(text)).toBe(0));
});
