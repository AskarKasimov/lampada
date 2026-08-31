export type CaptureRequest = {
  locale: string;
  slideId: string;
  formatId: string;
};

export function parseCaptureRequest(
  search: string,
  locales: string[],
  slideIds: string[],
  formatIds: string[],
): CaptureRequest | null {
  const params = new URLSearchParams(search);
  const locale = params.get("locale");
  const slideId = params.get("capture");
  const formatId = params.get("format");

  if (
    locale === null ||
    slideId === null ||
    formatId === null ||
    !locales.includes(locale) ||
    !slideIds.includes(slideId) ||
    !formatIds.includes(formatId)
  ) {
    return null;
  }

  return { locale, slideId, formatId };
}
