import { config } from "zod";

// Schemas decide when they are built whether to compile themselves with eval. The admin's policy forbids it, and
// even asking is reported as a violation, so this module must come before any schema.
config({ jitless: true });
