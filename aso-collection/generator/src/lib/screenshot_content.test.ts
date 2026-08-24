import { expect, test } from "bun:test";

import { loadContent } from "./screenshot_content";

const rootYaml = `
version: 1
default_locale: ru
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
    subtitle: ["по 5 минут в день."]
    theme: light
    screenshot: 01-today.png
`;

test("загружает общий манифест, локаль по умолчанию и её слайды", async () => {
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
