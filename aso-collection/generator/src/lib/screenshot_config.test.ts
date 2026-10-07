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

test("разрешает нулевой и отрицательный сдвиг телефона для полного показа экрана", () => {
  expect(parseRootConfig(rootYaml.replace("phone_translate_y: 5", "phone_translate_y: 0"))
    .formats[0]?.phoneTranslateY).toBe(0);
  expect(parseRootConfig(rootYaml.replace("phone_translate_y: 5", "phone_translate_y: -3"))
    .formats[0]?.phoneTranslateY).toBe(-3);
  expect(() => parseRootConfig(rootYaml.replace("phone_translate_y: 5", "phone_translate_y: .inf")))
    .toThrow("phone_translate_y");
});

test("читает цвет маски статусной строки и отклоняет некорректный цвет", () => {
  expect(parseLocaleConfig(`${localeYaml}    status_bar_background: '#736e68'\n`, "ru")
    .slides[0]?.statusBarBackground).toBe("#736e68");
  expect(parseLocaleConfig(localeYaml, "ru").slides[0]?.statusBarBackground).toBe("#FAF0E3");
  expect(() => parseLocaleConfig(`${localeYaml}    status_bar_background: 'wrong'\n`, "ru"))
    .toThrow("status_bar_background");
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

test("все коммитные манифесты ссылаются на соседние изображения", () => {
  const publicDir = join(import.meta.dir, "../../public");
  const root = parseRootConfig(readFileSync(join(publicDir, "config.yaml"), "utf8"));

  for (const localeId of root.locales) {
    const locale = parseLocaleConfig(
      readFileSync(join(publicDir, "locales", localeId, "config.yaml"), "utf8"),
      localeId,
    );
    for (const slide of locale.slides) {
      expect(existsSync(join(publicDir, "locales", localeId, slide.screenshot))).toBe(true);
    }
  }
});
