import { invitation, joinWithPasskey, manage } from "../helpers";
import { api, expect, places, test } from "./helpers";

test.describe.configure({ mode: "serial" });

/** What is published in the admin appears on the website at once: worker, signature, shared cache, page. */
test("a story changed in the admin changes on the website", async ({ browser, request }) => {
  const { article } = await places("sw");
  const path = article ?? "";
  expect(await (await request.get(path)).text()).not.toContain("Muhtasari mpya kabisa");
  const { id } = await api(`articles/${path.split("/").pop()}?locale=sw`);
  const editor = await (
    await browser.newContext({ locale: "en-GB", baseURL: "http://localhost:3001" })
  ).newPage();
  await joinWithPasskey(
    editor,
    "asha@example.test",
    "Asha",
    invitation("asha@example.test", "editor_in_chief"),
  );
  await editor.goto(`/content/${id}`);
  await editor.getByLabel("Standfirst").fill("Muhtasari mpya kabisa.");
  await expect(editor.getByRole("status").first()).toHaveText("All changes saved");
  await editor.getByRole("button", { name: "Publish changes" }).click();
  await expect(editor.getByText("Unpublished changes")).toHaveCount(0);
  await expect
    .poll(async () => (await (await request.get(path)).text()).includes("Muhtasari mpya kabisa"), {
      timeout: 20_000,
    })
    .toBe(true);

  // A page of the publisher's own: written, published, in the footer, withdrawn.
  await editor.goto("/pages/about");
  await editor.getByLabel("Title").fill("Kuhusu Mfano");
  await editor.getByRole("button", { name: "Publish", exact: true }).click();
  await expect(editor.getByText("Published.", { exact: true })).toBeVisible();
  await expect
    .poll(async () => (await (await request.get("/about")).text()).includes("Kuhusu Mfano"), {
      timeout: 20_000,
    })
    .toBe(true);
  expect(await (await request.get("/")).text()).toContain("Kuhusu Mfano");
  await editor.getByRole("button", { name: "Withdraw" }).click();
  await editor.getByRole("dialog").getByRole("button", { name: "Withdraw" }).click();
  await expect(editor.getByText("Withdrawn. Readers no longer see this page.")).toBeVisible();
  await expect.poll(async () => (await request.get("/about")).status(), { timeout: 20_000 }).toBe(404);
  await editor.getByRole("button", { name: "Publish", exact: true }).click();
  await expect.poll(async () => (await request.get("/about")).status(), { timeout: 20_000 }).toBe(200);
});

const sign = (body: string, ago = 0) =>
  manage(
    "shell",
    "-v0",
    "-c",
    `import time
from newsplatform.seo.delivery import LOCAL_SECRET, sign
t = int(time.time()) - ${ago}
print(t, sign(LOCAL_SECRET, t, b'''${body}'''))`,
  ).split(" ");

test("the website obeys a signed order, once, for five minutes", async ({ request }) => {
  const body = JSON.stringify({ id: `t${Date.now()}`, tags: ["latest"], paths: ["/"] });
  const send = async (text: string, [time = "", signature = ""]: string[]) =>
    (
      await request.post("/api/revalidate", {
        data: Buffer.from(text),
        headers: { "x-timestamp": time, "x-signature": signature, "content-type": "application/json" },
      })
    ).status();
  const order = sign(body);
  expect(await send(body, order)).toBe(200);
  expect(await send(body, order)).toBe(409);
  expect(await send(body.replace("latest", "site"), order)).toBe(401);
  expect(await send(body, sign(body, 400))).toBe(401);
  expect(await send(body, [order[0] ?? "", "0".repeat(64)])).toBe(401);
  expect((await request.post("/api/revalidate", { data: "{}" })).status()).toBe(401);
  expect((await request.get("/api/revalidate")).status()).toBe(405);
});

test("the theme published in the admin is the website's", async ({ request }) => {
  const html = await (await request.get("/")).text();
  const { theme } = await (await fetch("http://127.0.0.1:8010/api/v1/site-config")).json();
  expect(html).toContain(`href="${theme.css}"`);
  expect((await request.get(theme.css)).status()).toBe(200);
});
