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
  expect(parseLocaleConfig(localeYaml, "ru").slides[0]?.statusBarBackground).toBeUndefined();
  expect(() => parseLocaleConfig(`${localeYaml}    status_bar_background: 'wrong'\n`, "ru"))
    .toThrow("status_bar_background");
});

test("читает области увеличения в долях экрана и не выпускает их за экран", () => {
  expect(parseLocaleConfig(localeYaml, "ru").slides[0]?.zoom).toEqual([]);
  const zoom = (list: string) =>
    parseLocaleConfig(`${localeYaml}    zoom: ${list}\n`, "ru").slides[0]?.zoom;
  expect(
    zoom("[{ x: 0.06, y: 0.41, width: 0.9, height: 0.19, scale: 1.35 }, { x: 0.63, y: 0.07, width: 0.34, height: 0.04, scale: 1.8 }]"),
  ).toEqual([
    { x: 0.06, y: 0.41, width: 0.9, height: 0.19, scale: 1.35, shape: "card" },
    { x: 0.63, y: 0.07, width: 0.34, height: 0.04, scale: 1.8, shape: "card" },
  ]);
  expect(() => zoom("[{ x: 0.2, y: 0.4, width: 0.9, height: 0.2, scale: 1.3 }]")).toThrow("zoom[0]");
  expect(() => zoom("[{ x: 0, y: 0.9, width: 1, height: 0.2, scale: 1.3 }]")).toThrow("zoom[0]");
  expect(() => zoom("[{ x: 0, y: 0.4, width: 0, height: 0.2, scale: 1.3 }]")).toThrow("zoom[0].width");
  // Карточка меньше оригинала не увеличивает, а прячет экран.
  expect(() => zoom("[{ x: 0, y: 0.4, width: 0.5, height: 0.2, scale: 0.8 }]")).toThrow("zoom[0].scale");
  expect(() => zoom("{ x: 0, y: 0.4, width: 0.5, height: 0.2, scale: 1.3 }")).toThrow("zoom");
});

test("форма области увеличения по умолчанию карточка, овал задаётся явно", () => {
  const shape = (extra: string) =>
    parseLocaleConfig(
      `${localeYaml}    zoom: [{ x: 0.6, y: 0.07, width: 0.3, height: 0.04, scale: 1.7${extra} }]\n`,
      "ru",
    ).slides[0]?.zoom[0]?.shape;
  expect(shape("")).toBe("card");
  expect(shape(", shape: pill")).toBe("pill");
  expect(() => shape(", shape: star")).toThrow("zoom[0].shape");
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

test("отрицательный сдвиг телефона поднимает его над нижним краем", () => {
  const root = parseRootConfig(rootYaml.replace("phone_translate_y: 5", "phone_translate_y: -2"));
  expect(root.formats[0]?.phoneTranslateY).toBe(-2);
});

test("тема экрана по умолчанию светлая и принимает только light или dark", () => {
  expect(parseLocaleConfig(localeYaml, "ru").slides[0]?.screenTheme).toBe("light");
  const dark = localeYaml.replace("theme: light", "theme: light\n    screen_theme: dark");
  expect(parseLocaleConfig(dark, "ru").slides[0]?.screenTheme).toBe("dark");
  expect(() =>
    parseLocaleConfig(localeYaml.replace("theme: light", "theme: light\n    screen_theme: sepia"), "ru"),
  ).toThrow("screen_theme");
});

const placementsYaml = `
placements:
  - id: header
    label: Product page header
    layout: title
    width: 3840
    height: 1646
    safe_area: { x: 1097, y: 493, width: 1646, height: 661 }
`;

test("плейсменты необязательны и проверяют безопасную зону", () => {
  expect(parseRootConfig(rootYaml).placements).toEqual([]);
  const root = parseRootConfig(rootYaml + placementsYaml);
  expect(root.placements[0]).toEqual({
    id: "header",
    label: "Product page header",
    layout: "title",
    width: 3840,
    height: 1646,
    safeArea: { x: 1097, y: 493, width: 1646, height: 661 },
  });
  expect(() =>
    parseRootConfig(rootYaml + placementsYaml.replace("width: 1646", "width: 3000")),
  ).toThrow("safe_area");
  expect(() => parseRootConfig(rootYaml + placementsYaml.replace("layout: title", "layout: grid"))).toThrow(
    "layout",
  );
});

test("локаль задаёт заголовок и скриншоты плейсмента", () => {
  const locale = parseLocaleConfig(
    `${localeYaml}placements:
  header:
    title: [Ближе к Богу]
  search-results:
    title: [Листай]
    screenshots: [01-today.png]
`,
    "ru",
  );
  expect(locale.placements).toEqual({
    header: { title: ["Ближе к Богу"], screenshots: [] },
    "search-results": { title: ["Листай"], screenshots: ["01-today.png"] },
  });
  expect(parseLocaleConfig(localeYaml, "ru").placements).toEqual({});
});
