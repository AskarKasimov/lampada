import { expect, test } from "bun:test";

import {
  GLYPH_RATIO,
  fitFontSize,
  TITLE_SIDE_RATIO,
  headerHeight,
  sharedTitleFontSize,
  titleFontSize,
} from "./title_layout";

const format = {
  id: "app-store-6-9",
  label: "App Store",
  width: 1320,
  height: 2868,
  phoneWidthRatio: 0.84,
  phoneTranslateY: 3,
};

test("зона заголовка заканчивается у верхнего края видимого телефона", () => {
  const phoneHeight = 1320 * 0.84 * (2082 / 1022);
  expect(headerHeight(format)).toBeCloseTo(2868 - phoneHeight * 0.97, 5);
});

test("короткий заголовок получает кегль крупнее длинного", () => {
  const short = titleFontSize(["Из захожанина", "в прихожанина"], format);
  const long = titleFontSize(["Святые отвечают", "на твои будничные", "вопросы"], format);
  expect(short).toBeGreaterThan(long);
});

test("кегль ограничен шириной самой длинной строки", () => {
  const size = titleFontSize(["Святые отвечают", "на твои будничные", "вопросы"], format);
  expect(size * 17 * GLYPH_RATIO).toBeLessThanOrEqual(1320 * (1 - 2 * TITLE_SIDE_RATIO) + 0.001);
});

test("кегль ограничен высотой зоны и потолком", () => {
  const tall = titleFontSize(["А", "Б", "В", "Г", "Д", "Е", "Ж"], format);
  expect(tall * 7 * 1.08).toBeLessThanOrEqual(headerHeight(format));
  expect(titleFontSize(["Бог"], format)).toBeLessThanOrEqual(1320 * 0.11);
});

test("все заголовки формата получают кегль самого тесного", () => {
  const titles = [
    ["Из захожанина", "в прихожанина"],
    ["Основы веры", "простыми словами"],
  ];
  expect(sharedTitleFontSize(titles, format)).toBe(
    titleFontSize(["Основы веры", "простыми словами"], format),
  );
});

test("кегль вписывает строки в прямоугольник по ширине и высоте", () => {
  const lines = ["Листай не ленту,", "а Евангелие"];
  expect(fitFontSize(lines, 2168, 10_000)).toBeCloseTo(2168 / (16 * GLYPH_RATIO), 5);
  expect(fitFontSize(lines, 10_000, 400)).toBeCloseTo(400 / (2 * 1.08), 5);
});
