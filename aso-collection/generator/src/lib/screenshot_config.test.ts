import { expect, test } from "bun:test";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

import {
  parseLocaleConfig,
  parseRootConfig,
  screenshotUrl,
  selectLocale,
} from "./screenshot_config";

const rootYaml = `
version: 1
locales: [ru]
formats:
  - id: rustore
    label: RuStore
    width: 1080
    height: 1920
    phone_width_ratio: 0.74
    phone_translate_y: 5
`;

const localeYaml = `
locale: ru
slides:
  - id: hero
    label: Главный
    title: [Православие, "по 5 минут в день."]
    subtitle: ["Открыл, прочитал, закрыл.", "Непрочитанное не копится."]
    theme: light
    screenshot: 01-today.png
`;

test("принимает полный общий и локальный манифест", () => {
  const root = parseRootConfig(rootYaml);
  const locale = parseLocaleConfig(localeYaml, "ru");

  expect(root.formats[0]?.id).toBe("rustore");
  expect(root.locales).toEqual(["ru"]);
  expect(locale.slides[0]?.theme).toBe("light");
  expect(selectLocale(root, "en")).toBe("ru");
});

test("отклоняет неизвестную тему, повтор id и небезопасный путь", () => {
  expect(() => parseLocaleConfig(localeYaml.replace("light", "blue"), "ru")).toThrow(
    "theme",
  );
  expect(() =>
    parseLocaleConfig(
      `${localeYaml}
  - id: hero
    label: Повтор
    title: [Повтор]
    subtitle: [Повтор]
    theme: dark
    screenshot: 02-card.png
`,
      "ru",
    ),
  ).toThrow("duplicate");
  expect(() => screenshotUrl("ru", "../secret.png")).toThrow("screenshot");
});

test("отклоняет пустые строки и массивы", () => {
  expect(() => parseLocaleConfig(localeYaml.replace("title: [Православие, \"по 5 минут в день.\"]", "title: []"), "ru")).toThrow("title");
  expect(() => parseLocaleConfig(localeYaml.replace("label: Главный", "label: ''"), "ru")).toThrow("label");
});

test("коммитные манифесты ссылаются на соседние изображения", () => {
  const publicDir = join(import.meta.dir, "../../public");
  const root = parseRootConfig(readFileSync(join(publicDir, "config.yaml"), "utf8"));
  const locale = parseLocaleConfig(
    readFileSync(join(publicDir, "locales/ru/config.yaml"), "utf8"),
    "ru",
  );

  expect(root.locales[0]).toBe("ru");
  for (const slide of locale.slides) {
    expect(existsSync(join(publicDir, "locales/ru", slide.screenshot))).toBe(true);
  }
});
