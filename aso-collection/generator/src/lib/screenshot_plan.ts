export type ScreenshotPlanItem = {
  slideId: string;
  filename: string;
  width: number;
  height: number;
};

export type CaptureArgs = {
  locale: string;
  format: string;
  outputDir: string;
};

export function buildScreenshotPlan(
  slides: { id: string }[],
  format: { id: string; width: number; height: number },
): ScreenshotPlanItem[] {
  return slides.map((slide, index) => {
    if (!/^[A-Za-z0-9_-]+$/.test(slide.id)) {
      throw new Error("slide id должен быть безопасным slug.");
    }
    return {
      slideId: slide.id,
      filename: `${String(index + 1).padStart(2, "0")}-${slide.id}.png`,
      width: format.width,
      height: format.height,
    };
  });
}

export function parseCaptureArgs(args: string[]): CaptureArgs {
  const values = new Map<string, string>();
  for (let index = 0; index < args.length; index += 2) {
    const option = args[index];
    const value = args[index + 1];
    if (
      (option !== "--locale" && option !== "--format" && option !== "--output-dir") ||
      value === undefined ||
      value.trim().length === 0 ||
      values.has(option)
    ) {
      throw new Error(`Неверные аргументы capture: ${option ?? ""}`);
    }
    values.set(option, value);
  }

  const locale = values.get("--locale");
  const format = values.get("--format");
  const outputDir = values.get("--output-dir");
  if (!locale || !format || !outputDir) {
    throw new Error("capture требует --locale, --format и --output-dir");
  }

  return { locale, format, outputDir };
}
