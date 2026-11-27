import type { Kept } from "./store";

/** The saved page: the stories kept in this browser, drawn from the page's own row template. */
export function savedList(list: Kept[]) {
  for (const box of document.querySelectorAll("[data-saved]")) {
    const ul = box.querySelector("ul");
    const row = box.querySelector<HTMLTemplateElement>("template[data-row]")?.content.firstElementChild;
    const empty = box.querySelector<HTMLElement>("[data-empty]");
    if (!ul || !row || !empty) continue;
    ul.replaceChildren(
      ...list.map((k) => {
        const li = row.cloneNode(true) as HTMLElement;
        const set = (selector: string, text: string) => {
          const el = li.querySelector(selector);
          if (el) el.textContent = text;
        };
        li.querySelector("a")?.setAttribute("href", k.path);
        set("[data-category]", k.category);
        set("[data-headline]", k.headline);
        const b = li.querySelector("button");
        b?.setAttribute("aria-label", `${b.getAttribute("aria-label")}: ${k.headline}`);
        if (b) b.dataset.path = k.path;
        return li;
      }),
    );
    ul.hidden = list.length === 0;
    empty.hidden = list.length > 0;
  }
}
