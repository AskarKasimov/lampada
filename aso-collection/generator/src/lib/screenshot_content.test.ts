import { expect, test } from "bun:test";

import { loadContent } from "./screenshot_content";

const rootYaml = `
version: 1
locales: [ru]
formats:
  - id: rustore
    label: RuStore
    width: 1080
    height: 1920
    phone_width_ratio: 0.65
    phone_translate_y: 7
`;

const localeYaml = `
locale: ru
slides:
  - id: hero
    label: Главный
    title: [Православие]
    theme: light
    screenshot: 01-today.png
`;

test("загружает общий манифест, первую локаль и её слайды", async () => {
  const requests: string[] = [];
  const fetcher = async (url: string) => {
    requests.push(url);
    return new Response(url === "/config.yaml" ? rootYaml : localeYaml);
  };

  await expect(loadContent(fetcher, "en")).resolves.toMatchObject({
    locale: "ru",
    locales: ["ru"],
  });
  expect(requests).toEqual(["/config.yaml", "/locales/ru/config.yaml"]);
});

test("называет URL неудачного запроса", async () => {
  const fetcher = async () => new Response("not found", { status: 404 });

  await expect(loadContent(fetcher, null)).rejects.toThrow("/config.yaml");
});

test("собирает плейсменты, для которых у локали есть тексты", async () => {
  const root = `${rootYaml}placements:
  - id: header
    label: Header
    layout: title
    width: 3840
    height: 1646
    safe_area: { x: 1097, y: 493, width: 1646, height: 661 }
  - id: search-results
    label: Search
    layout: phones
    width: 3840
    height: 2560
    safe_area: { x: 836, y: 765, width: 2168, height: 1030 }
`;
  const locale = `${localeYaml}placements:
  header:
    title: [Ближе к Богу]
`;
  const fetcher = async (url: string) => new Response(url === "/config.yaml" ? root : locale);

  const content = await loadContent(fetcher, "ru");
  expect(content.placements.map((placement) => placement.id)).toEqual(["header"]);
  expect(content.placements[0]?.title).toEqual(["Ближе к Богу"]);
});
