import createClient, { type ClientOptions } from "openapi-fetch";
import type { components, paths } from "./generated/public";

export type Schemas = components["schemas"];
export const createPublicClient = (options?: ClientOptions) => createClient<paths>(options);
