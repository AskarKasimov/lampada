import { expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { chromium } from "playwright";

import { parseLocaleConfig, parseRootConfig } from "../lib/screenshot_config";
import { sharedTitleFontSize } from "../lib/title_layout";
import { StoreSlide } from "./store_slide";

const publicDir = join(import.meta.dir, "../../public");
const root = () => parseRootConfig(readFileSync(join(publicDir, "config.yaml"), "utf8"));
const locale = () => parseLocaleConfig(
  readFileSync(join(publicDir, "locales/ru/config.yaml"), "utf8"), "ru",
);
const css = readFileSync(join(import.meta.dir, "../app/globals.css"), "utf8");

test("телефон помещается по ширине и не перекрывает заголовок", async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    const slides = locale().slides;
    const slide = slides[0]!;
    for (const format of root().formats) {
      const page = await browser.newPage({ viewport: { width: format.width, height: format.height } });
      try {
        const titleSize = sharedTitleFontSize(slides.map((item) => item.title), format);
        await page.setContent(`<style>${css}</style>${renderToStaticMarkup(
          React.createElement(StoreSlide, { slide, locale: "ru", format, titleSize }),
        )}`);
        const phone = await page.locator('img[src="/mockup.png"]').evaluate((img) => {
          const rect = img.parentElement!.getBoundingClientRect();
          return { top: rect.top, bottom: rect.bottom, left: rect.left, right: rect.right };
        });
        expect(phone.top).toBeGreaterThanOrEqual(0);
        expect(phone.left).toBeGreaterThanOrEqual(0);
        expect(phone.right).toBeLessThanOrEqual(format.width);
        const title = await page.locator("h1").boundingBox();
        expect(phone.top).toBeGreaterThan(title!.y + title!.height);
      } finally {
        await page.close();
      }
    }
  } finally {
    await browser.close();
  }
});

test("карточки увеличения лежат над своими областями и не выходят за слайд", async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    const zoom = [
      { x: 0.06, y: 0.41, width: 0.9, height: 0.19, scale: 1.35, shape: "card" as const },
      // У правого края экрана: карточка обязана прижаться внутрь слайда.
      { x: 0.63, y: 0.07, width: 0.34, height: 0.04, scale: 2.4, shape: "card" as const },
    ];
    const slides = locale().slides;
    const slide = { ...slides[0]!, zoom };
    for (const format of root().formats) {
      const page = await browser.newPage({ viewport: { width: format.width, height: format.height } });
      try {
        const titleSize = sharedTitleFontSize(slides.map((item) => item.title), format);
        await page.setContent(`<style>${css}</style>${renderToStaticMarkup(
          React.createElement(StoreSlide, { slide, locale: "ru", format, titleSize }),
        )}`);
        const cards = await page.locator("[data-zoom]").evaluateAll((nodes) =>
          nodes.map((node) => {
            const rect = node.getBoundingClientRect();
            return { x: rect.left, y: rect.top, width: rect.width, height: rect.height };
          }),
        );
        const screen = await page.locator(`img[alt="${slide.label}"]`).evaluate((img) => {
          const rect = img.parentElement!.getBoundingClientRect();
          return { y: rect.top, width: rect.width, height: rect.height };
        });
        const title = (await page.locator("h1").boundingBox())!;
        expect(cards).toHaveLength(zoom.length);
        cards.forEach((card, index) => {
          const region = zoom[index]!;
          expect(card.x).toBeGreaterThanOrEqual(0);
          expect(card.x + card.width).toBeLessThanOrEqual(format.width);
          expect(card.y).toBeGreaterThan(title.y + title.height);
          expect(Math.abs(card.width - screen.width * region.width * region.scale)).toBeLessThan(1);
          const regionCenter = screen.y + screen.height * (region.y + region.height / 2);
          expect(Math.abs(card.y + card.height / 2 - regionCenter)).toBeLessThan(2);
        });
      } finally {
        await page.close();
      }
    }
  } finally {
    await browser.close();
  }
});

test("овальная карточка скруглена на половину высоты и без подложки", async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage();
    const format = root().formats[0]!;
    const zoom = [
      { x: 0.63, y: 0.077, width: 0.33, height: 0.04, scale: 1.7, shape: "pill" as const },
    ];
    const slide = { ...locale().slides[0]!, zoom };
    await page.setContent(`<style>${css}</style>${renderToStaticMarkup(
      React.createElement(StoreSlide, {
        slide, locale: "ru", format,
        titleSize: sharedTitleFontSize([slide.title], format),
      }),
    )}`);
    const pill = await page.locator("[data-zoom]").evaluate((node) => {
      const style = getComputedStyle(node);
      return {
        height: node.getBoundingClientRect().height,
        radius: parseFloat(style.borderTopLeftRadius),
        background: style.backgroundColor,
      };
    });
    expect(pill.radius).toBeCloseTo(pill.height / 2, 1);
    expect(pill.background).toBe("rgba(0, 0, 0, 0)");
  } finally {
    await browser.close();
  }
});

test("маска статусной строки берёт явный цвет вместо цвета темы", async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage();
    const format = root().formats[0]!;
    const slide = { ...locale().slides[0]!, statusBarBackground: "#736e68" };
    await page.setContent(`<style>${css}</style>${renderToStaticMarkup(
      React.createElement(StoreSlide, {
        slide, locale: "ru", format,
        titleSize: sharedTitleFontSize([slide.title], format),
      }),
    )}`);
    const background = await page.locator(`img[alt="${slide.label}"]`).evaluate((img) => {
      const mask = img.parentElement!.querySelector("div")!;
      return getComputedStyle(mask).backgroundColor;
    });
    expect(background).toBe("rgb(115, 110, 104)");
  } finally {
    await browser.close();
  }
});
