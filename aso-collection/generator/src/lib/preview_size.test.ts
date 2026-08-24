import { expect, test } from "bun:test";

import { previewSize } from "./preview_size";

test("сохраняет общую высоту и ширину по пропорциям формата", () => {
  const appStore = previewSize({ width: 1320, height: 2868 }, 420);
  const ruStore = previewSize({ width: 1080, height: 1920 }, 420);

  expect(appStore.height).toBe(420);
  expect(ruStore.height).toBe(420);
  expect(appStore.width).toBeCloseTo(193.31, 2);
  expect(ruStore.width).toBe(236.25);
  expect(ruStore.width).toBeGreaterThan(appStore.width);
});
