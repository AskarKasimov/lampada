import {
  parseLocaleConfig,
  parseRootConfig,
  selectLocale,
  type LocalePlacement,
  type LocaleSlide,
  type StoreFormat,
  type StorePlacement,
} from "./screenshot_config";

export type LoadedPlacement = StorePlacement & LocalePlacement;

export type LoadedContent = {
  locale: string;
  locales: string[];
  slides: LocaleSlide[];
  formats: StoreFormat[];
  placements: LoadedPlacement[];
};

export type ContentFetcher = (url: string) => Promise<Response>;

async function loadYaml(fetcher: ContentFetcher, url: string): Promise<string> {
  const response = await fetcher(url);
  if (!response.ok) {
    throw new Error(`Не удалось загрузить ${url}: HTTP ${response.status}`);
  }
  return response.text();
}

export async function loadContent(
  fetcher: ContentFetcher,
  requestedLocale: string | null,
): Promise<LoadedContent> {
  const root = parseRootConfig(await loadYaml(fetcher, "/config.yaml"));
  const locale = selectLocale(root, requestedLocale);
  const content = parseLocaleConfig(
    await loadYaml(fetcher, `/locales/${locale}/config.yaml`),
    locale,
  );

  return {
    locale: content.locale,
    locales: root.locales,
    slides: content.slides,
    formats: root.formats,
    // Плейсмент без текстов локали не показывается: креатив без заголовка
    // не собрать, а переводить его обязательно не для каждой локали.
    placements: root.placements.flatMap((placement) => {
      const local = content.placements[placement.id];
      return local ? [{ ...placement, ...local }] : [];
    }),
  };
}
