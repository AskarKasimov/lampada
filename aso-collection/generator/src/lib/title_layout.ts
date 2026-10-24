import type { StoreFormat } from "./screenshot_config";

// Пропорции public/mockup.png.
export const MOCKUP_WIDTH = 1022;
export const MOCKUP_HEIGHT = 2082;

export const TITLE_LINE_HEIGHT = 1.08;
export const TITLE_SIDE_RATIO = 0.04;
export const TITLE_TOP_RATIO = 0.02;
export const TITLE_GAP_RATIO = 0.015;

// Ширина символа Lora Bold в кириллице, в долях кегля: самые широкие
// строки по замеру canvas дают 0.614 («Основы веры», «простыми словами»),
// запас даёт letter-spacing -0.01em. Кегль считается заранее, а не замером
// DOM, чтобы capture не зависел от загрузки шрифта.
export const GLYPH_RATIO = 0.615;
const MAX_SIZE_RATIO = 0.11;

// Телефон прижат к низу слайда, поэтому всё выше его видимой части
// отдаётся заголовку. Зона одинакова для всех слайдов формата, и телефоны
// в витрине стоят на одной высоте.
export function headerHeight(format: StoreFormat): number {
  const phoneHeight =
    format.width * format.phoneWidthRatio * (MOCKUP_HEIGHT / MOCKUP_WIDTH);
  return format.height - phoneHeight * (1 - format.phoneTranslateY / 100);
}

// Самый крупный кегль, при котором строки помещаются в прямоугольник.
export function fitFontSize(lines: string[], width: number, height: number): number {
  const longest = Math.max(...lines.map((line) => line.length));
  return Math.min(
    width / (longest * GLYPH_RATIO),
    height / (lines.length * TITLE_LINE_HEIGHT),
  );
}

export function titleFontSize(lines: string[], format: StoreFormat): number {
  const textWidth = format.width * (1 - 2 * TITLE_SIDE_RATIO);
  const textHeight =
    headerHeight(format) - format.height * (TITLE_TOP_RATIO + TITLE_GAP_RATIO);
  return Math.min(format.width * MAX_SIZE_RATIO, fitFontSize(lines, textWidth, textHeight));
}

// Витрина смотрится одной серией, только если кегль общий: его задаёт
// заголовок, которому тесней всего.
export function sharedTitleFontSize(titles: string[][], format: StoreFormat): number {
  return Math.min(...titles.map((lines) => titleFontSize(lines, format)));
}
