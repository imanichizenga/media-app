import { describe, expect, it } from "vitest";
import { ApiError } from "../lib/api";

describe("ApiError.fields", () => {
  it("reads service errors", () =>
    expect(new ApiError(400, "x", "", { errors: [{ field: "bucket", message: "bad" }] }).fields).toEqual({
      bucket: "bad",
    }));
  it("reads serializer errors", () =>
    expect(new ApiError(400, "x", "", { errors: { email: ["bad", "worse"] } }).fields).toEqual({
      email: "bad worse",
    }));
  it("is empty otherwise", () => expect(new ApiError(500, "x", "").fields).toEqual({}));
});
