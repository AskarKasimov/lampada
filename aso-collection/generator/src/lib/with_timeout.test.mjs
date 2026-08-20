import assert from "node:assert/strict";
import test from "node:test";

import { ExportTimeoutError, withTimeout } from "./with_timeout.mjs";

test("withTimeout возвращает готовый экспорт", async () => {
  await assert.doesNotReject(
    withTimeout(Promise.resolve("data:image/png;base64,ok"), 20, "слайд 1"),
  );
});

test("withTimeout отклоняет зависший экспорт", async () => {
  await assert.rejects(
    withTimeout(new Promise(() => {}), 20, "слайд 1"),
    ExportTimeoutError,
  );
});
