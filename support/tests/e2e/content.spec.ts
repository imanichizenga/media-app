import { resolve } from "node:path";
import { AxeBuilder } from "@axe-core/playwright";
import type { Page } from "@playwright/test";
import { expect, invitation, joinWithPasskey, test, watch } from "./helpers";

test.describe.configure({ mode: "serial" });
const SAMPLE = resolve(import.meta.dirname, "../../../backend/newsplatform/media/samples/sample.mp4");
const HEADLINE = "Bandari ya Tanga yapokea meli mpya";
const problems: string[] = [];
let writer: Page;
let editor: Page;
let address: string;

const join = async (browser: import("@playwright/test").Browser, name: string, role: string) => {
  const page = await (
    await browser.newContext({ locale: "en-GB", viewport: { width: 1440, height: 900 } })
  ).newPage();
  await watch(page, problems);
  const email = `${name.toLowerCase()}@example.test`;
  await joinWithPasskey(page, email, name, invitation(email, role));
  return page;
};
const saved = (page: Page) => expect(page.getByRole("status").first()).toHaveText("All changes saved");
const body = (page: Page) => page.getByRole("textbox", { name: "Article text" });
const settled = async (page: Page, path: string) => {
  await page.goto(path);
  await expect(page.locator("main .bone")).toHaveCount(0, { timeout: 20_000 });
};

test.beforeAll(async ({ browser }) => {
  writer = await join(browser, "Neema", "journalist");
  editor = await join(browser, "Khamis", "editor_in_chief");
});
test.afterEach(() => expect(problems.splice(0)).toEqual([]));

test("writing: the first words are saved by themselves and survive a reload", async () => {
  await settled(writer, "/content");
  await writer.getByRole("button", { name: "New post" }).first().click();
  const dialog = writer.getByRole("dialog");
  await dialog.getByLabel("Headline").fill(HEADLINE);
  await dialog.getByLabel("Category").selectOption({ label: "Business" });
  await dialog.getByRole("button", { name: "Start writing" }).click();
  await writer.waitForURL(/content\/[0-9a-f-]{36}$/);
  address = new URL(writer.url()).pathname;
  await writer.getByLabel("Standfirst").fill("Meli kubwa zaidi kuwahi kutia nanga.");
  await body(writer).click();
  await writer.keyboard.type("Meli hiyo imebeba ");
  await writer.keyboard.press("ControlOrMeta+b");
  await writer.keyboard.type("tani elfu kumi");
  await writer.keyboard.press("ControlOrMeta+b");
  await writer.keyboard.type(" za mizigo.");
  await writer.keyboard.press("Enter");
  await writer.getByRole("button", { name: "Heading 2" }).click();
  await writer.keyboard.type("Kinachofuata");
  await saved(writer);
  await settled(writer, address);
  await expect(body(writer).locator("strong")).toHaveText("tani elfu kumi");
  await expect(body(writer).getByRole("heading", { level: 2 })).toHaveText("Kinachofuata");
  await expect(writer.getByLabel("Standfirst")).toHaveValue("Meli kubwa zaidi kuwahi kutia nanga.");
});

test("a lost connection keeps the words and sends them later", async () => {
  await writer.context().setOffline(true);
  await writer.getByLabel("Standfirst").fill("Meli kubwa kabisa.");
  await expect(writer.getByText("Offline. Your text is kept here and will be sent.")).toBeVisible();
  await writer.context().setOffline(false);
  await saved(writer);
  await settled(writer, address);
  await expect(writer.getByLabel("Standfirst")).toHaveValue("Meli kubwa kabisa.");
});

test("a picture: uploaded where it is needed, placed, and not publishable without a credit", async () => {
  const picture = await writer.screenshot({ type: "jpeg", quality: 60 });
  await body(writer).click();
  await writer.keyboard.press("ControlOrMeta+End");
  await writer.getByRole("button", { name: "Insert" }).click();
  await writer.getByRole("menuitem", { name: "Picture" }).click();
  const card = writer.getByRole("dialog", { name: "Picture", exact: true });
  await card.getByRole("button", { name: "Choose a picture" }).click();
  const picker = writer.getByRole("dialog", { name: "Choose a picture" });
  await picker
    .locator("input[type=file]")
    .setInputFiles({ name: "bandari.jpg", mimeType: "image/jpeg", buffer: picture });
  const tile = picker.getByRole("button", { name: /bandari\.jpg/ });
  await expect(tile.locator("img")).toBeVisible({ timeout: 30_000 });
  await tile.click();
  await card.getByRole("button", { name: "Save" }).click();
  await expect(card.getByText("Something required is missing.")).toBeVisible();
  await card.getByLabel("Description").fill("Meli bandarini");
  await card.getByRole("button", { name: "Save" }).click();
  await expect(body(writer).getByRole("img", { name: "Meli bandarini" })).toBeVisible();
  await saved(writer);
  await expect(writer.getByText("Add a credit to every picture")).toBeVisible();

  await settled(writer, "/media");
  await writer.getByRole("button", { name: /bandari\.jpg/ }).click();
  const details = writer.getByRole("dialog", { name: "File details" });
  await details.getByLabel("Credit").fill("Neema / Mfano");
  const focal = details.getByRole("slider", { name: "Focal point" });
  await focal.focus();
  await writer.keyboard.press("ArrowLeft");
  await expect(focal).toHaveAttribute("aria-valuetext", "48%, 50%");
  await details.getByRole("button", { name: "Save" }).click();
  await expect(details.getByText("Saved.")).toBeVisible();
  await expect(details.getByText("Used in 1 place")).toBeVisible();
});

test("every status change is a decision by the right person", async () => {
  await settled(writer, address);
  await expect(writer.getByText("Add a credit to every picture")).toHaveCount(0);
  await expect(writer.getByRole("button", { name: "Approve", exact: true })).toHaveCount(0);
  await writer.getByRole("button", { name: "Submit for review" }).click();
  await expect(writer.getByText("Submitted", { exact: true })).toBeVisible();
  await settled(writer, "/content"); // gives the lock back

  await settled(editor, "/content");
  await editor.getByLabel("Status").selectOption("submitted");
  await editor.getByRole("link", { name: HEADLINE }).click();
  await editor.waitForURL(`**${address}`);
  await editor.getByRole("button", { name: "Preview" }).click();
  const preview = editor.getByRole("dialog", { name: "Preview" });
  await expect(preview.getByRole("heading", { name: HEADLINE })).toBeVisible();
  await expect(preview.getByRole("img", { name: "Meli bandarini" })).toBeVisible();
  await editor.keyboard.press("Escape");
  await editor.getByRole("button", { name: "Request changes" }).click();
  const why = editor.getByRole("dialog", { name: "Request changes" });
  await why.getByLabel("Why?").fill("Ongeza chanzo cha pili.");
  await why.getByRole("button", { name: "Request changes" }).click();
  await expect(editor.getByText("Draft", { exact: true })).toBeVisible();
  await expect(editor.getByText("Ongeza chanzo cha pili.")).toBeVisible();
  await settled(editor, "/content");

  await settled(writer, address);
  await expect(writer.getByText("Ongeza chanzo cha pili.")).toBeVisible();
  await writer.getByRole("button", { name: "Submit for review" }).click();
  await expect(writer.getByText("Submitted", { exact: true })).toBeVisible();
  await settled(writer, "/content");

  await settled(editor, address);
  await editor.getByRole("button", { name: "Approve", exact: true }).click();
  await expect(editor.getByText("Approved", { exact: true })).toBeVisible();
  await editor.getByRole("button", { name: "Publish", exact: true }).click();
  await expect(editor.getByText("SW: /biashara/bandari-ya-tanga-yapokea-meli-mpya")).toBeVisible();
});

test("a change to a live article waits until it is published", async () => {
  await editor.getByLabel("Standfirst").fill("Meli kubwa kabisa kuwahi kufika.");
  await saved(editor);
  await expect(editor.getByText("Unpublished changes")).toBeVisible();
  await editor.getByRole("button", { name: "Publish changes" }).click();
  await expect(editor.getByText("Unpublished changes")).toHaveCount(0);
});

test("an earlier version can be read and brought back", async () => {
  await editor.getByRole("tab", { name: "History" }).click();
  await editor
    .getByRole("button", { name: /Published · r/ })
    .last()
    .click();
  const dialog = editor.getByRole("dialog");
  await dialog.getByRole("button", { name: /^Restore r/ }).click();
  await expect(editor.getByLabel("Standfirst")).toHaveValue("Meli kubwa kabisa.");
  await saved(editor);
});

test("two people cannot write over each other", async () => {
  await settled(writer, address);
  await expect(writer.getByText("Khamis is editing this post.")).toBeVisible();
  await expect(writer.getByLabel("Standfirst")).not.toBeEditable();
  await writer.getByRole("button", { name: "Take over" }).click();
  await writer.getByLabel("Standfirst").fill("Imeandikwa na Neema.");
  await saved(writer);
  await editor.getByLabel("Standfirst").fill("Imeandikwa na Khamis.");
  await expect(editor.getByText(/Someone else is editing|Changed elsewhere/)).toBeVisible();
  await settled(writer, "/content");
  await settled(editor, address);
  await expect(editor.getByLabel("Standfirst")).toHaveValue("Imeandikwa na Neema.");
});

test("a video survives a cut connection, is processed, and plays", async () => {
  await settled(writer, "/media");
  let cut = 0;
  await writer.route("http://127.0.0.1:8333/**", (route) =>
    route.request().method() === "PUT" && cut++ < 2 ? route.abort() : route.continue(),
  );
  await writer.locator("main input[type=file]").first().setInputFiles(SAMPLE);
  await expect(writer.getByText("Uploaded. Processing continues.")).toBeVisible({ timeout: 30_000 });
  expect(cut).toBeGreaterThan(2);
  await writer.unroute("http://127.0.0.1:8333/**");
  const tile = writer.getByRole("button", { name: /sample\.mp4/ }).first();
  await expect(tile.locator("img")).toBeVisible({ timeout: 60_000 });
  await tile.click();
  await writer.getByRole("button", { name: "Play" }).click();
  await expect
    .poll(() => writer.locator("video").evaluate((v: HTMLVideoElement) => v.currentTime), { timeout: 20_000 })
    .toBeGreaterThan(0.2);
  await writer.keyboard.press("Escape");
});

test("a file that is not what it claims is refused", async () => {
  await writer
    .locator("main input[type=file]")
    .first()
    .setInputFiles({
      name: "jina.jpg",
      mimeType: "image/jpeg",
      buffer: Buffer.from("<script>alert(1)</script>"),
    });
  const tile = writer.getByRole("button", { name: /jina\.jpg/ }).first();
  await expect(tile.getByText("Rejected")).toBeVisible({ timeout: 30_000 });
  await tile.click();
  await expect(writer.getByText("This kind of file is not accepted.")).toBeVisible();
  await writer.keyboard.press("Escape");
});

test("a live update goes out from the editor", async () => {
  await settled(editor, "/content");
  await editor.getByLabel("Type").selectOption("live_blog");
  const row = editor.locator("main tbody tr").filter({ hasText: "Published" });
  await expect(editor.locator("main tbody tr").filter({ hasNotText: "Live blog" })).toHaveCount(0);
  await row.first().getByRole("link").click();
  await editor.getByRole("button", { name: "Live update", exact: true }).click();
  const dialog = editor.getByRole("dialog", { name: "Live update" });
  await dialog.getByRole("textbox").last().click();
  await editor.keyboard.type("Mvua imeanza kunyesha.");
  await dialog.getByRole("button", { name: "Publish update" }).click();
  await expect(dialog).toHaveCount(0);
  await expect(body(editor).getByText("Mvua imeanza kunyesha.")).toBeVisible();
});

test("a category keeps its readers when its address changes", async () => {
  await settled(editor, "/taxonomy");
  await editor.getByRole("button", { name: /^Edit Business/ }).click();
  const dialog = editor.getByRole("dialog", { name: "Business" });
  await dialog.locator('[name="sw.slug"]').fill("uchumi-na-biashara");
  await dialog.getByRole("button", { name: "Save" }).click();
  await expect(dialog).toHaveCount(0);
  await editor.getByRole("tab", { name: "Redirects" }).click();
  await expect(editor.getByRole("cell", { name: "/biashara", exact: true })).toBeVisible();
});

test("drafts of other people are out of reach", async ({ browser }) => {
  const other = await join(browser, "Zawadi", "journalist");
  await settled(other, "/content");
  await expect(other.getByText("No posts found")).toBeVisible();
  const status = await other.evaluate(
    async (id) => (await fetch(`/api/v1/posts/${id}`)).status,
    address.split("/").pop(),
  );
  expect(status).toBe(404);
  await other.close();
});

for (const theme of ["light", "dark"] as const)
  test(`the editor is accessible in the ${theme} theme`, async () => {
    await editor.context().addCookies([{ name: "theme", value: theme, url: "http://localhost:3001" }]);
    await settled(editor, address);
    for (const tab of ["Publish", "Details", "SEO", "Engagement", "History"]) {
      await editor.getByRole("tab", { name: tab }).click();
      await expect(editor.locator("main .bone")).toHaveCount(0);
      const { violations } = await new AxeBuilder({ page: editor })
        .withTags(["wcag2a", "wcag2aa", "wcag21aa", "wcag22aa"])
        .analyze();
      expect
        .soft(
          violations.map((v) => `${v.id}: ${v.nodes.map((n) => n.html.slice(0, 120)).join(" | ")}`),
          tab,
        )
        .toEqual([]);
    }
  });

test("the editor on a phone: no sideways scroll, every target at least 44px", async () => {
  await editor.setViewportSize({ width: 360, height: 740 });
  await settled(editor, address);
  expect(await editor.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(360);
  const small = await editor.evaluate(() =>
    [...document.querySelectorAll<HTMLElement>("main button, main a[href], main select")]
      .filter((e) => e.offsetParent && !e.matches(".sr-only"))
      .filter((e) => e.getBoundingClientRect().height < 44)
      .map((e) => `${e.tagName} ${e.textContent || e.ariaLabel} ${e.getBoundingClientRect().height}`),
  );
  expect(small).toEqual([]);
  await editor.setViewportSize({ width: 1440, height: 900 });
});

test("the editor's skeleton holds the place of what comes", async () => {
  await settled(editor, "/content"); // no one else holds the post: the notice about that is news, not layout
  let release = () => {};
  const gate = new Promise<void>((r) => {
    release = r;
  });
  const data = /\/api\/v1\/(?!auth\/session)/;
  await writer.route(data, async (route) => {
    await gate;
    await route.continue();
  });
  await writer.goto(address);
  await expect(writer.locator("main .bone").first()).toBeVisible();
  const place = (name: string) =>
    writer.evaluate((n) => {
      const at = (s: string) => {
        const r = document.querySelector(s)?.getBoundingClientRect();
        return r ? [Math.round(r.x), Math.round(r.y), Math.round(r.width)] : null;
      };
      return n === "before"
        ? { panel: at("[data-skeleton=panel]"), text: at("[data-skeleton=headline]") }
        : { panel: at("main aside"), text: at("main textarea") };
    }, name);
  const before = await place("before");
  release();
  await expect(writer.locator("main .bone")).toHaveCount(0);
  const after = await place("after");
  for (const key of ["panel", "text"] as const)
    for (const i of [0, 1, 2])
      expect
        .soft(
          Math.abs((before[key]?.[i] ?? -999) - (after[key]?.[i] ?? 999)),
          `${key} ${before[key]} ${after[key]}`,
        )
        .toBeLessThanOrEqual(8);
  await writer.unroute(data);
});
