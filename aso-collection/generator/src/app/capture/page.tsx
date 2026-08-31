"use client";

import { useEffect, useState } from "react";

import { StoreSlide } from "@/components/store_slide";
import { parseCaptureRequest } from "@/lib/capture_request";
import { loadContent, type LoadedContent } from "@/lib/screenshot_content";

export default function CapturePage() {
  const [content, setContent] = useState<LoadedContent | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const requestedLocale = params.get("locale");
    let cancelled = false;

    loadContent((url) => fetch(url), requestedLocale)
      .then((loaded) => {
        if (cancelled) return;
        const request = parseCaptureRequest(
          window.location.search,
          loaded.locales,
          loaded.slides.map((slide) => slide.id),
          loaded.formats.map((format) => format.id),
        );
        if (request === null || request.locale !== loaded.locale) {
          setError("Неизвестный запрос для снимка.");
          return;
        }
        setContent(loaded);
      })
      .catch((reason) => {
        if (!cancelled) {
          setError(reason instanceof Error ? reason.message : "Не удалось загрузить витрину.");
        }
      });

    return () => {
      cancelled = true;
    };
  }, []);

  if (error) {
    return <p role="alert">Ошибка capture: {error}</p>;
  }

  if (!content) {
    return <p>Загружаю слайд…</p>;
  }

  const request = parseCaptureRequest(
    window.location.search,
    content.locales,
    content.slides.map((slide) => slide.id),
    content.formats.map((format) => format.id),
  );
  const slide = content.slides.find((item) => item.id === request?.slideId);
  const format = content.formats.find((item) => item.id === request?.formatId);

  if (!slide || !format) {
    return <p role="alert">Ошибка capture: Неизвестный запрос для снимка.</p>;
  }

  return <StoreSlide slide={slide} locale={content.locale} format={format} />;
}
