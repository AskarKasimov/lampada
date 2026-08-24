import assert from "node:assert/strict";
import test from "node:test";

import { captureMode } from "./capture_mode.mjs";

test("служебный режим выбирает RuStore-кадр по URL", () => {
  assert.deepEqual(
    captureMode("?capture=hero&format=rustore", ["hero"], ["rustore"]),
    { slideId: "hero", formatId: "rustore" },
  );
});

test("служебный режим не принимает неизвестный кадр", () => {
  assert.equal(
    captureMode("?capture=other&format=rustore", ["hero"], ["rustore"]),
    null,
  );
});
