import { expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { chromium } from "playwright";

import { parseLocaleConfig, parseRootConfig } from "../lib/screenshot_config";
import { StoreSlide } from "./store_slide";

const publicDir = join(import.meta.dir, "../../public");
const root = () => parseRootConfig(readFileSync(join(publicDir, "config.yaml"), "utf8"));
const locale = () => parseLocaleConfig(
  readFileSync(join(publicDir, "locales/ru/config.yaml"), "utf8"), "ru",
);
const css = readFileSync(join(import.meta.dir, "../app/globals.css"), "utf8");

test("экран занимает почти всю ширину, телефон не перекрывает подписи и обрезается снизу", async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    for (const format of root().formats) {
      const page = await browser.newPage({ viewport: { width: format.width, height: format.height } });
      try {
        await page.setContent(`<style>${css}</style>${renderToStaticMarkup(
          React.createElement(StoreSlide, { slide: locale().slides[0]!, locale: "ru", format }),
        )}`);
        const phone = await page.locator('img[src="/mockup.png"]').evaluate((img) => {
          const rect = img.parentElement!.getBoundingClientRect();
          return { top: rect.top, bottom: rect.bottom, left: rect.left, right: rect.right };
        });
        expect(phone.top).toBeGreaterThanOrEqual(0);
        expect(phone.left).toBeGreaterThanOrEqual(0);
        expect(phone.right).toBeLessThanOrEqual(format.width);
        const screen = await page.locator('img[alt="Главный"]').boundingBox();
        const subtitle = await page.locator("p").boundingBox();
        expect(screen!.width).toBeGreaterThanOrEqual(format.width * 0.80);
        expect(screen!.width).toBeLessThan(format.width);
        expect(phone.top).toBeGreaterThan(subtitle!.y + subtitle!.height);
        expect(phone.bottom).toBeGreaterThan(format.height);
      } finally {
        await page.close();
      }
    }
  } finally {
    await browser.close();
  }
});

test("статусная строка Евангелия сохраняет цвет затемнённого фона исходника", async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage();
    await page.setContent(`<style>${css}</style>${renderToStaticMarkup(
      React.createElement(StoreSlide, {
        slide: locale().slides.find((slide) => slide.id === "gospel")!,
        locale: "ru", format: root().formats[0]!,
      }),
    )}`);
    const background = await page.locator('img[alt="Евангелие"]').evaluate((img) => {
      const mask = img.parentElement!.querySelector("div")!;
      return getComputedStyle(mask).backgroundColor;
    });
    expect(background).toBe("rgb(115, 110, 104)");
  } finally {
    await browser.close();
  }
});
