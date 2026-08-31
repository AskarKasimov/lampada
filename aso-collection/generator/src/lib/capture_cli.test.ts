import { expect, test } from "bun:test";
import { mkdtempSync, readFileSync, readdirSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

import { parseLocaleConfig, parseRootConfig } from "./screenshot_config";

test(
  "CLI рендерит текущие RuStore-слайды YAML точного размера во временный каталог",
  async () => {
    const generatorDir = join(import.meta.dir, "../..");
    const publicDir = join(generatorDir, "public");
    const root = parseRootConfig(readFileSync(join(publicDir, "config.yaml"), "utf8"));
    const format = root.formats.find((item) => item.id === "rustore");
    expect(format).toBeDefined();
    const locale = parseLocaleConfig(
      readFileSync(join(publicDir, "locales", "ru", "config.yaml"), "utf8"),
      "ru",
    );
    const expectedFiles = locale.slides.map(
      (slide, index) => `${String(index + 1).padStart(2, "0")}-${slide.id}.png`,
    );
    const outputDir = mkdtempSync(join(tmpdir(), "lampada-screenshots-"));
    try {
      const process = Bun.spawn(
        [
          "bun",
          "run",
          "capture",
          "--",
          "--locale",
          "ru",
          "--format",
          "rustore",
          "--output-dir",
          outputDir,
        ],
        { cwd: generatorDir, stdout: "pipe", stderr: "pipe" },
      );

      expect(await process.exited).toBe(0);
      expect(readdirSync(outputDir).sort()).toEqual(expectedFiles.sort());
      for (const filename of readdirSync(outputDir)) {
        const png = readFileSync(join(outputDir, filename));
        expect(png.readUInt32BE(16)).toBe(format?.width);
        expect(png.readUInt32BE(20)).toBe(format?.height);
      }
    } finally {
      rmSync(outputDir, { force: true, recursive: true });
    }
  },
  60_000,
);
