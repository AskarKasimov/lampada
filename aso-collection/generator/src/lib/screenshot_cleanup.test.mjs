import assert from "node:assert/strict";
import test from "node:test";

import { screenshotCleanupMaskHeight } from "./screenshot_cleanup.mjs";

test("маска перекрывает верхние артефакты от debug-сборки", () => {
  assert.equal(screenshotCleanupMaskHeight, 8);
});
