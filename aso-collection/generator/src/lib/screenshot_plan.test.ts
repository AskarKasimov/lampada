import { expect, test } from "bun:test";

import { buildScreenshotPlan, parseCaptureArgs } from "./screenshot_plan";

test("сохраняет YAML-порядок и нумерует выходные файлы", () => {
  expect(
    buildScreenshotPlan(
      [{ id: "hero" }, { id: "session" }],
      { id: "rustore", width: 1080, height: 1920 },
    ),
  ).toEqual([
    { slideId: "hero", filename: "01-hero.png", width: 1080, height: 1920 },
    { slideId: "session", filename: "02-session.png", width: 1080, height: 1920 },
  ]);
});

test("отклоняет пустой путь output-каталога", () => {
  expect(() =>
    parseCaptureArgs(["--locale", "ru", "--format", "rustore", "--output-dir", ""]),
  ).toThrow("output-dir");
});

test("не даёт slide id выйти за output-каталог", () => {
  expect(() =>
    buildScreenshotPlan(
      [{ id: "../../outside" }],
      { id: "rustore", width: 1080, height: 1920 },
    ),
  ).toThrow("slide id");
});
