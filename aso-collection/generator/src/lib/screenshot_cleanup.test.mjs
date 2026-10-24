import assert from "node:assert/strict";
import test from "node:test";

import { screenshotCleanupMaskHeight } from "./screenshot_cleanup.mjs";

test("маска перекрывает status bar, но не плашки верхней панели", () => {
  assert.equal(screenshotCleanupMaskHeight, 7);
});
