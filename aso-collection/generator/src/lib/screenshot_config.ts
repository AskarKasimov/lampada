import { parse } from "yaml";

export type ScreenshotTheme = "light" | "dark";

export type StoreFormat = {
  id: string;
  label: string;
  width: number;
  height: number;
  phoneWidthRatio: number;
  phoneTranslateY: number;
};

export type PlacementLayout = "title" | "phones";

export type Rect = { x: number; y: number; width: number; height: number };

// card — область на светлой подложке; pill — обрезка овалом точно по
// элементу-плашке, без подложки.
export type ZoomShape = "card" | "pill";

// Область экрана в долях его ширины и высоты и во сколько раз её
// показать крупнее, чем на телефоне.
export type ZoomRegion = Rect & { scale: number; shape: ZoomShape };

// Креативы App Store вне ленты скриншотов: шапка страницы и выдача поиска.
export type StorePlacement = {
  id: string;
  label: string;
  layout: PlacementLayout;
  width: number;
  height: number;
  // Art Safe Area из шаблонов Apple: всё важное должно лежать внутри неё,
  // остальное устройство может обрезать.
  safeArea: Rect;
};

export type RootConfig = {
  version: number;
  locales: string[];
  formats: StoreFormat[];
  placements: StorePlacement[];
};

export type LocalePlacement = {
  title: string[];
  screenshots: string[];
};

export type LocaleSlide = {
  id: string;
  label: string;
  title: string[];
  theme: ScreenshotTheme;
  screenTheme: ScreenshotTheme;
  screenshot: string;
  statusBarBackground?: string;
  // Области экрана, которые слайд показывает крупными карточками поверх
  // телефона.
  zoom: ZoomRegion[];
};

export type LocaleConfig = {
  locale: string;
  slides: LocaleSlide[];
  placements: Record<string, LocalePlacement>;
};

export class ScreenshotConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ScreenshotConfigError";
  }
}

function yamlObject(source: string, name: string): Record<string, unknown> {
  let value: unknown;
  try {
    value = parse(source);
  } catch (error) {
    throw new ScreenshotConfigError(
      `${name}: invalid YAML${error instanceof Error ? `: ${error.message}` : ""}`,
    );
  }
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new ScreenshotConfigError(`${name}: expected object`);
  }
  return value as Record<string, unknown>;
}

function stringValue(value: unknown, name: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new ScreenshotConfigError(`${name}: expected non-empty string`);
  }
  return value;
}

function numberValue(value: unknown, name: string): number {
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) {
    throw new ScreenshotConfigError(`${name}: expected positive number`);
  }
  return value;
}

function finiteNumber(value: unknown, name: string): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new ScreenshotConfigError(`${name}: expected number`);
  }
  return value;
}

function colorValue(value: unknown, name: string): string {
  const color = stringValue(value, name);
  if (!/^#[0-9a-fA-F]{6}$/.test(color)) {
    throw new ScreenshotConfigError(`${name}: expected #RRGGBB`);
  }
  return color;
}

function stringArray(value: unknown, name: string): string[] {
  if (!Array.isArray(value) || value.length === 0) {
    throw new ScreenshotConfigError(`${name}: expected non-empty array`);
  }
  return value.map((item, index) => stringValue(item, `${name}[${index}]`));
}

function recordArray(value: unknown, name: string): Record<string, unknown>[] {
  if (!Array.isArray(value) || value.length === 0) {
    throw new ScreenshotConfigError(`${name}: expected non-empty array`);
  }
  return value.map((item, index) => {
    if (item === null || typeof item !== "object" || Array.isArray(item)) {
      throw new ScreenshotConfigError(`${name}[${index}]: expected object`);
    }
    return item as Record<string, unknown>;
  });
}

function unique(values: string[], name: string) {
  if (new Set(values).size !== values.length) {
    throw new ScreenshotConfigError(`${name}: duplicate value`);
  }
}

function localeCode(value: unknown, name: string): string {
  const locale = stringValue(value, name);
  if (!/^[a-z]{2}(?:-[A-Z]{2})?$/.test(locale)) {
    throw new ScreenshotConfigError(`${name}: invalid locale`);
  }
  return locale;
}

function themeValue(value: unknown, name: string): ScreenshotTheme {
  const theme = stringValue(value, name);
  if (theme === "light" || theme === "dark") return theme;
  throw new ScreenshotConfigError(`${name}: expected light or dark`);
}

function nonNegative(value: unknown, name: string): number {
  if (typeof value !== "number" || !Number.isFinite(value) || value < 0) {
    throw new ScreenshotConfigError(`${name}: expected non-negative number`);
  }
  return value;
}

function zoomShape(value: unknown, name: string): ZoomShape {
  const shape = stringValue(value, name);
  if (shape === "card" || shape === "pill") return shape;
  throw new ScreenshotConfigError(`${name}: expected card or pill`);
}

function zoomValue(raw: Record<string, unknown>, name: string): ZoomRegion {
  const zoom = {
    x: nonNegative(raw.x, `${name}.x`),
    y: nonNegative(raw.y, `${name}.y`),
    width: numberValue(raw.width, `${name}.width`),
    height: numberValue(raw.height, `${name}.height`),
    scale: numberValue(raw.scale, `${name}.scale`),
    shape: raw.shape === undefined ? "card" : zoomShape(raw.shape, `${name}.shape`),
  };
  if (zoom.x + zoom.width > 1 || zoom.y + zoom.height > 1) {
    throw new ScreenshotConfigError(`${name}: outside screen`);
  }
  if (zoom.scale <= 1) {
    throw new ScreenshotConfigError(`${name}.scale: expected greater than 1`);
  }
  return zoom;
}

function layoutValue(value: unknown, name: string): PlacementLayout {
  const layout = stringValue(value, name);
  if (layout === "title" || layout === "phones") return layout;
  throw new ScreenshotConfigError(`${name}: expected title or phones`);
}

function placementValue(raw: Record<string, unknown>, name: string): StorePlacement {
  const width = numberValue(raw.width, `${name}.width`);
  const height = numberValue(raw.height, `${name}.height`);
  const area = raw.safe_area;
  if (area === null || typeof area !== "object" || Array.isArray(area)) {
    throw new ScreenshotConfigError(`${name}.safe_area: expected object`);
  }
  const box = area as Record<string, unknown>;
  const safeArea = {
    x: nonNegative(box.x, `${name}.safe_area.x`),
    y: nonNegative(box.y, `${name}.safe_area.y`),
    width: numberValue(box.width, `${name}.safe_area.width`),
    height: numberValue(box.height, `${name}.safe_area.height`),
  };
  if (safeArea.x + safeArea.width > width || safeArea.y + safeArea.height > height) {
    throw new ScreenshotConfigError(`${name}.safe_area: outside canvas`);
  }
  return {
    id: stringValue(raw.id, `${name}.id`),
    label: stringValue(raw.label, `${name}.label`),
    layout: layoutValue(raw.layout, `${name}.layout`),
    width,
    height,
    safeArea,
  };
}

export function parseRootConfig(source: string): RootConfig {
  const raw = yamlObject(source, "root config");
  const version = numberValue(raw.version, "version");
  const locales = stringArray(raw.locales, "locales").map((locale, index) =>
    localeCode(locale, `locales[${index}]`),
  );
  unique(locales, "locales");

  const formats = recordArray(raw.formats, "formats").map((format, index) => ({
    id: stringValue(format.id, `formats[${index}].id`),
    label: stringValue(format.label, `formats[${index}].label`),
    width: numberValue(format.width, `formats[${index}].width`),
    height: numberValue(format.height, `formats[${index}].height`),
    phoneWidthRatio: numberValue(
      format.phone_width_ratio,
      `formats[${index}].phone_width_ratio`,
    ),
    // Отрицательное значение поднимает телефон и оставляет поле снизу.
    phoneTranslateY: finiteNumber(
      format.phone_translate_y,
      `formats[${index}].phone_translate_y`,
    ),
  }));
  unique(formats.map((format) => format.id), "formats");

  const placements =
    raw.placements === undefined
      ? []
      : recordArray(raw.placements, "placements").map((placement, index) =>
          placementValue(placement, `placements[${index}]`),
        );
  unique(placements.map((placement) => placement.id), "placements");

  return { version, locales, formats, placements };
}

export function parseLocaleConfig(source: string, expectedLocale: string): LocaleConfig {
  const raw = yamlObject(source, `locale ${expectedLocale}`);
  const locale = localeCode(raw.locale, "locale");
  if (locale !== expectedLocale) {
    throw new ScreenshotConfigError(`locale: expected ${expectedLocale}`);
  }

  const slides = recordArray(raw.slides, "slides").map((slide, index) => {
    const theme = themeValue(slide.theme, `slides[${index}].theme`);
    // Тема самого скриншота: под неё красится подменный status bar.
    const screenTheme =
      slide.screen_theme === undefined
        ? "light"
        : themeValue(slide.screen_theme, `slides[${index}].screen_theme`);
    const screenshot = stringValue(slide.screenshot, `slides[${index}].screenshot`);
    screenshotUrl(locale, screenshot);
    return {
      id: stringValue(slide.id, `slides[${index}].id`),
      label: stringValue(slide.label, `slides[${index}].label`),
      title: stringArray(slide.title, `slides[${index}].title`),
      theme,
      screenTheme,
      screenshot,
      // Без переопределения маска красится по screenTheme; задавайте цвет,
      // когда исходник затемнён, например панелью толкования.
      statusBarBackground:
        slide.status_bar_background === undefined
          ? undefined
          : colorValue(
              slide.status_bar_background,
              `slides[${index}].status_bar_background`,
            ),
      zoom:
        slide.zoom === undefined
          ? []
          : recordArray(slide.zoom, `slides[${index}].zoom`).map((region, zoomIndex) =>
              zoomValue(region, `slides[${index}].zoom[${zoomIndex}]`),
            ),
    };
  });
  unique(slides.map((slide) => slide.id), "slides");

  const placements: Record<string, LocalePlacement> = {};
  if (raw.placements !== undefined) {
    const map = raw.placements;
    if (map === null || typeof map !== "object" || Array.isArray(map)) {
      throw new ScreenshotConfigError("placements: expected object");
    }
    for (const [id, value] of Object.entries(map as Record<string, unknown>)) {
      if (value === null || typeof value !== "object" || Array.isArray(value)) {
        throw new ScreenshotConfigError(`placements.${id}: expected object`);
      }
      const item = value as Record<string, unknown>;
      const screenshots =
        item.screenshots === undefined
          ? []
          : stringArray(item.screenshots, `placements.${id}.screenshots`);
      for (const screenshot of screenshots) screenshotUrl(locale, screenshot);
      placements[id] = {
        title: stringArray(item.title, `placements.${id}.title`),
        screenshots,
      };
    }
  }

  return { locale, slides, placements };
}

export function selectLocale(root: RootConfig, requested: string | null): string {
  return requested !== null && root.locales.includes(requested)
    ? requested
    : root.locales[0]!;
}

export function screenshotUrl(locale: string, filename: string): string {
  localeCode(locale, "locale");
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]*\.png$/.test(filename)) {
    throw new ScreenshotConfigError("screenshot: expected sibling PNG filename");
  }
  return `/locales/${locale}/${filename}`;
}
