# Admin design notes

- **Type:** Newsreader for headings, Inter for interface text. Sizes are in rem and follow the reader's setting.
- **Colour:** the published theme, like the public product. Red marks the active place and the primary button; errors are rust, and destructive buttons are outlined (ADR-0029).
- **Appearance:** the preview is the real screens in real windows, scaled. Nothing is published until it passes contrast in every theme.
- **Skeletons:** `Bone` sits inside the real element and inherits its line height. Table skeletons reserve the action button's height. E2E compares positions (8px) and CLS (< 0.05) on every page.
- **Targets:** 44px minimum (`tap`), checked at 360px width.
- **Interruption:** step-up appears over the current page and then finishes the original action.
- **Language:** Swahili by default. A test keeps both catalogues in step, variables included.

- **Editor:** the same renderer as the website, so a card in the text looks as readers will see it. Cards open in a dialog; moving works with buttons as well as dragging. A picture without a description cannot be placed, and without a credit cannot be published.
- **Overlays:** black and white come from the tokens; dialogs dim the page in both themes.
- **Time:** always the newsroom's clock (`lib/time.ts`).

Reviewed by eye on 2026-11-23: dashboard, integration detail, audit log (light, desktop), settings (dark, Swahili, phone). On 2026-11-24: content list, editor with every panel, preview, media library, file details, calendar, categories, author page.
