"use client";

import { useEffect, useRef, useState } from "react";
import { toPng } from "html-to-image";
import JSZip from "jszip";

import { StoreSlide } from "@/components/store_slide";
import { withTimeout } from "@/lib/with_timeout.mjs";
import { loadContent, type LoadedContent } from "@/lib/screenshot_content";

const EXPORT_TIMEOUT_MS = 30_000;
const SANS = "var(--font-inter), -apple-system, system-ui, sans-serif";
const ACCENT = "#966116";

type Slide = LoadedContent["slides"][number];
type Format = LoadedContent["formats"][number];

function Preview({
  slide,
  locale,
  index,
  format,
  onExport,
}: {
  slide: Slide;
  locale: string;
  index: number;
  format: Format;
  onExport: (id: string) => void;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(0.15);

  useEffect(() => {
    const node = ref.current;
    if (!node) return;
    const observer = new ResizeObserver(() => {
      setScale(node.getBoundingClientRect().width / format.width);
    });
    observer.observe(node);
    return () => observer.disconnect();
  }, [format.width]);

  return (
    <div>
      <div
        ref={ref}
        onClick={() => onExport(slide.id)}
        title="Кликните, чтобы скачать"
        style={{
          width: "100%",
          aspectRatio: `${format.width}/${format.height}`,
          overflow: "hidden",
          cursor: "pointer",
        }}
      >
        <div
          style={{
            width: format.width,
            height: format.height,
            transform: `scale(${scale})`,
            transformOrigin: "top left",
          }}
        >
          <StoreSlide slide={slide} locale={locale} format={format} />
        </div>
      </div>
      <p style={{ textAlign: "center", fontSize: 12, color: "#888", margin: "7px 0 0" }}>
        {index + 1}. {slide.label}
      </p>
    </div>
  );
}

export default function Page() {
  const [content, setContent] = useState<LoadedContent | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [requestedLocale, setRequestedLocale] = useState<string | null | undefined>(
    undefined,
  );
  const [busy, setBusy] = useState<string | null>(null);
  const [exportError, setExportError] = useState<string | null>(null);
  const [formatIndex, setFormatIndex] = useState(0);
  const exports = useRef<Record<string, HTMLDivElement | null>>({});
  const format = content?.formats[formatIndex];

  useEffect(() => {
    setRequestedLocale(new URLSearchParams(window.location.search).get("locale"));
  }, []);

  useEffect(() => {
    if (requestedLocale === undefined) return;
    let cancelled = false;
    setContent(null);
    setLoadError(null);
    loadContent((url) => fetch(url), requestedLocale)
      .then((loaded) => {
        if (!cancelled) setContent(loaded);
      })
      .catch((error) => {
        if (!cancelled) {
          setLoadError(
            error instanceof Error ? error.message : "Не удалось загрузить конфигурацию.",
          );
        }
      });
    return () => {
      cancelled = true;
    };
  }, [requestedLocale]);

  if (loadError) return <p role="alert">Ошибка конфигурации: {loadError}</p>;
  if (!content || !format) return <p>Загружаю конфигурацию…</p>;
  const loadedContent = content;
  const selectedFormat = format;

  function changeLocale(locale: string) {
    const url = new URL(window.location.href);
    url.searchParams.set("locale", locale);
    window.history.replaceState(null, "", url);
    setRequestedLocale(locale);
  }

  async function renderBlob(id: string, element: HTMLDivElement) {
    // html-to-image не умеет снимать узел за пределами вьюпорта.
    element.style.left = "0px";
    element.style.opacity = "1";
    element.style.zIndex = "-1";
    try {
      await Promise.all(
        Array.from(element.querySelectorAll("img")).map((image) =>
          image.complete
            ? Promise.resolve()
            : new Promise<void>((resolve) => {
                image.onload = () => resolve();
                image.onerror = () => resolve();
              }),
        ),
      );
      await new Promise((resolve) => setTimeout(resolve, 400));
      const options = { width: selectedFormat.width, height: selectedFormat.height, pixelRatio: 1, cacheBust: true };
      await withTimeout(toPng(element, options), EXPORT_TIMEOUT_MS, `${id}, прогрев`);
      await new Promise((resolve) => setTimeout(resolve, 150));
      const url = await withTimeout(toPng(element, options), EXPORT_TIMEOUT_MS, id);
      const image = new Image();
      image.src = url;
      await image.decode();
      const canvas = document.createElement("canvas");
      canvas.width = selectedFormat.width;
      canvas.height = selectedFormat.height;
      canvas.getContext("2d")!.drawImage(image, 0, 0, selectedFormat.width, selectedFormat.height);
      const slideIndex = loadedContent.slides.findIndex((slide) => slide.id === id);
      const name = `${String(slideIndex + 1).padStart(2, "0")}-${id}-${selectedFormat.width}x${selectedFormat.height}.png`;
      const blob = await new Promise<Blob>((resolve) => canvas.toBlob((value) => resolve(value!)));
      return { name, blob };
    } finally {
      element.style.left = "-9999px";
      element.style.opacity = "";
      element.style.zIndex = "";
    }
  }

  async function exportOne(id: string) {
    const element = exports.current[id];
    if (!element) return;
    setExportError(null);
    setBusy(id);
    try {
      const { name, blob } = await renderBlob(id, element);
      const link = document.createElement("a");
      link.href = URL.createObjectURL(blob);
      link.download = name;
      document.body.appendChild(link);
      link.click();
      link.remove();
    } catch (error) {
      setExportError(error instanceof Error ? error.message : "Не удалось экспортировать слайд.");
    } finally {
      setBusy(null);
    }
  }

  async function exportAll() {
    setExportError(null);
    setBusy("all");
    try {
      const zip = new JSZip();
      for (const slide of loadedContent.slides) {
        const element = exports.current[slide.id];
        if (!element) continue;
        setBusy(slide.id);
        const { name, blob } = await renderBlob(slide.id, element);
        zip.file(name, blob);
      }
      const link = document.createElement("a");
      link.href = URL.createObjectURL(await zip.generateAsync({ type: "blob" }));
      link.download = `lampada-screenshots-${loadedContent.locale}-${selectedFormat.id}-${selectedFormat.width}x${selectedFormat.height}.zip`;
      link.click();
    } catch (error) {
      setExportError(error instanceof Error ? error.message : "Не удалось экспортировать архив.");
    } finally {
      setBusy(null);
    }
  }

  return (
    <div style={{ minHeight: "100vh", background: "#111", padding: "32px 24px", fontFamily: SANS }}>
      <div style={{ maxWidth: 1440, margin: "0 auto" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 28 }}>
          <div>
            <h1 style={{ fontSize: 20, fontWeight: 700, color: "#fff", margin: "0 0 3px" }}>Лампада — скриншоты магазинов</h1>
            <p style={{ fontSize: 12, color: "#666", margin: 0 }}>{loadedContent.slides.length} слайда · {loadedContent.locale.toUpperCase()} · клик по превью — скачать</p>
          </div>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            <select value={loadedContent.locale} onChange={(event) => changeLocale(event.target.value)}>
              {loadedContent.locales.map((locale) => <option key={locale} value={locale}>{locale.toUpperCase()}</option>)}
            </select>
            <select value={formatIndex} onChange={(event) => setFormatIndex(Number(event.target.value))}>
              {loadedContent.formats.map((item, index) => <option key={item.id} value={index}>{item.label} — {item.width}×{item.height}</option>)}
            </select>
            <button onClick={exportAll} disabled={Boolean(busy)} style={{ background: busy ? "#333" : ACCENT, color: "#fff", border: "none", borderRadius: 8, padding: "9px 20px", fontSize: 13, fontWeight: 600 }}>
              {busy === "all" ? "Пакую zip…" : busy ? `${busy}…` : "Скачать все"}
            </button>
          </div>
        </div>
        {exportError && <p role="alert" style={{ margin: "0 0 20px", color: "#ffb4a9", fontSize: 13 }}>{exportError}</p>}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(190px, 1fr))", gap: 20 }}>
          {loadedContent.slides.map((slide, index) => <Preview key={slide.id} slide={slide} locale={loadedContent.locale} index={index} format={selectedFormat} onExport={exportOne} />)}
        </div>
      </div>
      <div style={{ position: "absolute", top: 0, overflow: "hidden" }}>
        {loadedContent.slides.map((slide) => (
          <div key={`off-${slide.id}`} ref={(element) => { exports.current[slide.id] = element; }} style={{ position: "absolute", left: "-9999px", top: 0, width: selectedFormat.width, height: selectedFormat.height }}>
            <StoreSlide slide={slide} locale={loadedContent.locale} format={selectedFormat} />
          </div>
        ))}
      </div>
    </div>
  );
}
