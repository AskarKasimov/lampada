import assert from "node:assert/strict";
import test from "node:test";

import { exportFormats } from "./store_formats.mjs";

test("RuStore экспортирует портретный кадр 9:16", () => {
  const ruStore = exportFormats.find((format) => format.id === "rustore");

  assert.deepEqual(ruStore, {
    id: "rustore",
    label: "RuStore",
    w: 1080,
    h: 1920,
    phoneWidthRatio: 0.65,
    phoneTranslateY: 7,
  });
});
