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

export type RootConfig = {
  version: number;
  defaultLocale: string;
  locales: string[];
  formats: StoreFormat[];
};

export type LocaleSlide = {
  id: string;
  label: string;
  title: string[];
  subtitle: string[];
  theme: ScreenshotTheme;
  screenshot: string;
};

export type LocaleConfig = {
  locale: string;
  slides: LocaleSlide[];
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

export function parseRootConfig(source: string): RootConfig {
  const raw = yamlObject(source, "root config");
  const version = numberValue(raw.version, "version");
  const defaultLocale = localeCode(raw.default_locale, "default_locale");
  const locales = stringArray(raw.locales, "locales").map((locale, index) =>
    localeCode(locale, `locales[${index}]`),
  );
  unique(locales, "locales");
  if (!locales.includes(defaultLocale)) {
    throw new ScreenshotConfigError("default_locale: missing from locales");
  }

  const formats = recordArray(raw.formats, "formats").map((format, index) => ({
    id: stringValue(format.id, `formats[${index}].id`),
    label: stringValue(format.label, `formats[${index}].label`),
    width: numberValue(format.width, `formats[${index}].width`),
    height: numberValue(format.height, `formats[${index}].height`),
    phoneWidthRatio: numberValue(
      format.phone_width_ratio,
      `formats[${index}].phone_width_ratio`,
    ),
    phoneTranslateY: numberValue(
      format.phone_translate_y,
      `formats[${index}].phone_translate_y`,
    ),
  }));
  unique(formats.map((format) => format.id), "formats");

  return { version, defaultLocale, locales, formats };
}

export function parseLocaleConfig(source: string, expectedLocale: string): LocaleConfig {
  const raw = yamlObject(source, `locale ${expectedLocale}`);
  const locale = localeCode(raw.locale, "locale");
  if (locale !== expectedLocale) {
    throw new ScreenshotConfigError(`locale: expected ${expectedLocale}`);
  }

  const slides = recordArray(raw.slides, "slides").map((slide, index) => {
    const theme = themeValue(slide.theme, `slides[${index}].theme`);
    const screenshot = stringValue(slide.screenshot, `slides[${index}].screenshot`);
    screenshotUrl(locale, screenshot);
    return {
      id: stringValue(slide.id, `slides[${index}].id`),
      label: stringValue(slide.label, `slides[${index}].label`),
      title: stringArray(slide.title, `slides[${index}].title`),
      subtitle: stringArray(slide.subtitle, `slides[${index}].subtitle`),
      theme,
      screenshot,
    };
  });
  unique(slides.map((slide) => slide.id), "slides");

  return { locale, slides };
}

export function selectLocale(root: RootConfig, requested: string | null): string {
  return requested !== null && root.locales.includes(requested)
    ? requested
    : root.defaultLocale;
}

export function screenshotUrl(locale: string, filename: string): string {
  localeCode(locale, "locale");
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]*\.png$/.test(filename)) {
    throw new ScreenshotConfigError("screenshot: expected sibling PNG filename");
  }
  return `/locales/${locale}/${filename}`;
}
