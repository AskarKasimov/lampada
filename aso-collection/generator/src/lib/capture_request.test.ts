import { expect, test } from "bun:test";

import { parseCaptureRequest } from "./capture_request";

test("отдаёт известные locale, slide и format для capture-страницы", () => {
  expect(
    parseCaptureRequest(
      "?locale=ru&capture=hero&format=rustore",
      ["ru"],
      ["hero"],
      ["rustore"],
    ),
  ).toEqual({ locale: "ru", slideId: "hero", formatId: "rustore" });
});

test("отклоняет capture-запрос с неизвестным слайдом", () => {
  expect(
    parseCaptureRequest(
      "?locale=ru&capture=other&format=rustore",
      ["ru"],
      ["hero"],
      ["rustore"],
    ),
  ).toBeNull();
});
