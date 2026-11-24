import createClient, { type ClientOptions } from "openapi-fetch";
import type { components, paths } from "./generated/admin";

export type Schemas = components["schemas"];
export const createAdminClient = (options?: ClientOptions) => createClient<paths>(options);
