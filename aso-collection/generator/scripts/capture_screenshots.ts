import { createServer } from "node:net";
import { readdir, readFile, stat } from "node:fs/promises";
import { join } from "node:path";
import { spawn } from "node:child_process";

import { chromium } from "playwright";

import { parseLocaleConfig, parseRootConfig } from "../src/lib/screenshot_config";
import { buildScreenshotPlan, parseCaptureArgs } from "../src/lib/screenshot_plan";

const START_TIMEOUT_MS = 30_000;

async function freePort(): Promise<number> {
  const server = createServer();
  await new Promise<void>((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => resolve());
  });
  const address = server.address();
  if (!address || typeof address === "string") {
    throw new Error("Не удалось выбрать локальный порт для capture.");
  }
  await new Promise<void>((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
  return address.port;
}

async function run(command: string[], message: string) {
  await new Promise<void>((resolve, reject) => {
    const child = spawn(command[0]!, command.slice(1), { cwd: process.cwd(), stdio: "inherit" });
    child.once("error", reject);
    child.once("exit", (code) => (code === 0 ? resolve() : reject(new Error(message))));
  });
}

async function waitFor(url: string) {
  const deadline = Date.now() + START_TIMEOUT_MS;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(url);
      if (response.ok) return;
    } catch {
      // Сервер Next стартует асинхронно.
    }
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error(`Capture-сервер не запустился за ${START_TIMEOUT_MS / 1000} с.`);
}

async function ensureEmptyDirectory(path: string) {
  const directory = await stat(path).catch(() => null);
  if (!directory?.isDirectory()) {
    throw new Error("output-dir должен быть существующим каталогом.");
  }
  if ((await readdir(path)).length > 0) {
    throw new Error("output-dir должен быть пустым каталогом.");
  }
}

async function waitForAssets() {
  await Promise.all(
    Array.from(document.images).map(async (image) => {
      if (!image.complete) {
        await new Promise<void>((resolve) => {
          image.addEventListener("load", () => resolve(), { once: true });
          image.addEventListener("error", () => resolve(), { once: true });
        });
      }
      await image.decode().catch(() => undefined);
    }),
  );
  await document.fonts.ready;
}

async function main() {
  const args = parseCaptureArgs(process.argv.slice(2));
  await ensureEmptyDirectory(args.outputDir);

  const publicDir = join(process.cwd(), "public");
  const root = parseRootConfig(await readFile(join(publicDir, "config.yaml"), "utf8"));
  if (!root.locales.includes(args.locale)) {
    throw new Error(`Неизвестная locale: ${args.locale}`);
  }
  const locale = parseLocaleConfig(
    await readFile(join(publicDir, "locales", args.locale, "config.yaml"), "utf8"),
    args.locale,
  );
  const format = root.formats.find((item) => item.id === args.format);
  if (!format) {
    throw new Error(`Неизвестный format: ${args.format}`);
  }
  const plan = buildScreenshotPlan(locale.slides, format);

  await run(["bun", "run", "build"], "Не удалось собрать генератор перед capture.");
  const port = await freePort();
  const server = spawn(
    "bun",
    ["run", "start", "--", "--hostname", "127.0.0.1", "--port", String(port)],
    // Сервер останавливается штатно после capture: не выводим его SIGTERM как ошибку CLI.
    { cwd: process.cwd(), stdio: "ignore" },
  );

  let browser: Awaited<ReturnType<typeof chromium.launch>> | undefined;
  try {
    const origin = `http://127.0.0.1:${port}`;
    await waitFor(`${origin}/capture`);
    browser = await chromium.launch({ headless: true });

    for (const item of plan) {
      const context = await browser.newContext({
        deviceScaleFactor: 1,
        viewport: { width: item.width, height: item.height },
      });
      const page = await context.newPage();
      try {
        const url = new URL("/capture", origin);
        url.searchParams.set("locale", locale.locale);
        url.searchParams.set("capture", item.slideId);
        url.searchParams.set("format", format.id);
        await page.goto(url.toString(), { waitUntil: "networkidle" });
        await page.evaluate(waitForAssets);
        await page.screenshot({ path: join(args.outputDir, item.filename), type: "png" });
      } finally {
        await context.close();
      }
    }
  } catch (error) {
    if (error instanceof Error && error.message.includes("Executable doesn't exist")) {
      throw new Error("Не найден Chromium: выполните bunx playwright install chromium.");
    }
    throw error;
  } finally {
    await browser?.close();
    server.kill();
    await new Promise<void>((resolve) => server.once("exit", () => resolve()));
  }
}

await main();
