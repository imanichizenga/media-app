# Admin design notes

- **Type:** Newsreader for headings, Inter for interface text. Sizes are in rem and follow the reader's setting.
- **Colour:** one accent. Red is reserved for breaking and live, so errors use rust (`danger`).
- **Skeletons:** `Bone` sits inside the real element and inherits its line height. Table skeletons reserve the action button's height. E2E compares positions (8px) and CLS (< 0.05) on every page.
- **Targets:** 44px minimum (`tap`), checked at 360px width.
- **Interruption:** step-up appears over the current page and then finishes the original action.
- **Language:** Swahili by default. A test keeps both catalogues in step, variables included.

Reviewed by eye on 2026-11-23: dashboard, integration detail, audit log (light, desktop), settings (dark, Swahili, phone).
