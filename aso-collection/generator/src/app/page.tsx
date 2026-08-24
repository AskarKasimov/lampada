"use client";

import React, { useEffect, useRef, useState } from "react";
import { toPng } from "html-to-image";
import JSZip from "jszip";
import { captureMode } from "../lib/capture_mode.mjs";
import { screenshotCleanupMaskHeight } from "../lib/screenshot_cleanup.mjs";
import { withTimeout } from "../lib/with_timeout.mjs";
import { loadContent, type LoadedContent } from "../lib/screenshot_content";
import {
  screenshotUrl,
  type LocaleSlide,
  type StoreFormat,
} from "../lib/screenshot_config";

/* ── Канва ─────────────────────────────────────────────────────────────── */

const EXPORT_TIMEOUT_MS = 30_000;

/* ── Палитра из lib/core/theme/app_colors.dart ─────────────────────────── */

const CREAM = "#FAF0E3";
const INK = "#362418";
// Не полупрозрачные чернила: на кремовом фоне 48% давали ~2:1 и подзаголовок
// пропадал. Это textSecondary из палитры приложения — 4.92:1, проходит AA.
const MUTED = "#776559";
const ACCENT = "#966116";
const DARK_BG = "#1E1712";
const DARK_INK = "#F2E6D8";
const DARK_MUTED = "#C9B8A8";

const SERIF = "var(--font-lora), Georgia, serif";
const SANS = "var(--font-inter), -apple-system, system-ui, sans-serif";

/* ── Макет телефона (промеры под mockup.png) ───────────────────────────── */

const MK_W = 1022;
const MK_H = 2082;
const SC_L = (52 / MK_W) * 100;
const SC_T = (46 / MK_H) * 100;
const SC_W = (918 / MK_W) * 100;
const SC_H = (1990 / MK_H) * 100;
const SC_RX = (126 / 918) * 100;
const SC_RY = (126 / 1990) * 100;

/** Разбивка заголовка по строкам — переносы задаём вручную, не автопереносом. */
function L({ lines }: { lines: string[] }) {
  return (
    <>
      {lines.map((l, i) =>
        i === 0 ? (
          <React.Fragment key={i}>{l}</React.Fragment>
        ) : (
          <React.Fragment key={i}>
            <br />
            {l}
          </React.Fragment>
        ),
      )}
    </>
  );
}

/**
 * Чистый статус-бар поверх реального.
 *
 * Скриншоты сняты с живого телефона: 17:03, перечёркнутый колокольчик и
 * жёлтые 38% в энергосбережении. На витрине это читается неряшливо, поэтому
 * верхнюю полосу перекрываем своей — 9:41 и полная батарея.
 *
 * Кегль считаем от ширины экрана в пикселях, а не в cqw: container queries
 * html-to-image при экспорте разрешает нестабильно.
 */
function StatusBar({ screenW }: { screenW: number }) {
  const fs = screenW * 0.045;
  const icon = fs * 0.95;
  return (
    <>
      <div
        style={{
          position: "absolute",
          left: 0,
          top: 0,
          width: "100%",
          height: `${screenshotCleanupMaskHeight}%`,
          background: CREAM,
          zIndex: 5,
        }}
      />
      <div
        style={{
          position: "absolute",
          left: 0,
          top: 0,
          width: "100%",
          height: `${5.6}%`,
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: `0 ${screenW * 0.085}px 0 ${screenW * 0.09}px`,
          zIndex: 6,
        }}
      >
        <span
          style={{
            fontFamily: SANS,
            fontWeight: 600,
            fontSize: fs,
            color: INK,
            letterSpacing: "-0.02em",
          }}
        >
          9:41
        </span>
        <div
          style={{ display: "flex", alignItems: "center", gap: screenW * 0.022 }}
        >
          <svg width={icon * 1.15} height={icon * 0.8} viewBox="0 0 18 12">
            {[0, 1, 2, 3].map((i) => (
              <rect
                key={i}
                x={i * 4.6}
                y={9 - i * 3}
                width="3"
                height={3 + i * 3}
                rx="1"
                fill={INK}
              />
            ))}
          </svg>
          <svg width={icon * 1.05} height={icon * 0.8} viewBox="0 0 16 12">
            <path d="M8 10.4 6.1 8.3a2.7 2.7 0 0 1 3.8 0L8 10.4Z" fill={INK} />
            <path
              d="M3.6 5.8a6.4 6.4 0 0 1 8.8 0"
              stroke={INK}
              strokeWidth="1.5"
              strokeLinecap="round"
            />
            <path
              d="M5.5 7.8a3.8 3.8 0 0 1 5 0"
              stroke={INK}
              strokeWidth="1.5"
              strokeLinecap="round"
            />
          </svg>
          <svg width={icon * 1.7} height={icon * 0.8} viewBox="0 0 26 12">
            <rect
              x="0.6"
              y="0.6"
              width="22"
              height="10.8"
              rx="3"
              stroke={INK}
              strokeOpacity="0.35"
              strokeWidth="1.2"
            />
            <rect x="2.2" y="2.2" width="18.8" height="7.6" rx="1.8" fill={INK} />
            <path
              d="M24.4 4.2v3.6c.9-.3 1.4-.9 1.4-1.8s-.5-1.5-1.4-1.8Z"
              fill={INK}
              fillOpacity="0.35"
            />
          </svg>
        </div>
      </div>
    </>
  );
}

function Phone({
  src,
  alt,
  width,
  style,
}: {
  src: string;
  alt: string;
  width: number;
  style?: React.CSSProperties;
}) {
  const screenW = width * (SC_W / 100);
  return (
    <div
      style={{ position: "relative", aspectRatio: `${MK_W}/${MK_H}`, width, ...style }}
    >
      <img
        src="/mockup.png"
        alt=""
        style={{ display: "block", width: "100%", height: "100%" }}
        draggable={false}
      />
      <div
        style={{
          position: "absolute",
          zIndex: 10,
          overflow: "hidden",
          left: `${SC_L}%`,
          top: `${SC_T}%`,
          width: `${SC_W}%`,
          height: `${SC_H}%`,
          borderRadius: `${SC_RX}% / ${SC_RY}%`,
        }}
      >
        <img
          src={src}
          alt={alt}
          style={{
            display: "block",
            width: "100%",
            height: "100%",
            objectFit: "cover",
            objectPosition: "top",
          }}
          draggable={false}
        />
        <StatusBar screenW={screenW} />
      </div>
    </div>
  );
}

/* ── Слайд ─────────────────────────────────────────────────────────────── */

function SlideView({
  s,
  locale,
  format,
}: {
  s: LocaleSlide;
  locale: string;
  format: StoreFormat;
}) {
  const dark = s.theme === "dark";
  const ink = dark ? DARK_INK : INK;
  const muted = dark ? DARK_MUTED : MUTED;
  const textLr = format.width * 0.08;
  const headTop = format.height * 0.055;
  const headMin = format.height * 0.235;

  return (
    <div
      style={{
        width: format.width,
        height: format.height,
        background: dark ? DARK_BG : CREAM,
        overflow: "hidden",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <div
        style={{
          padding: `${headTop}px ${textLr}px 0`,
          display: "flex",
          flexDirection: "column",
          minHeight: headMin,
          flexShrink: 0,
        }}
      >
        <h1
          style={{
            fontFamily: SERIF,
            // Кириллица длиннее английского: у референса 0.11–0.135 работало
            // на коротких словах вроде "Scan anything", здесь строки вдвое
            // длиннее и на том же кегле уезжали в третью строку. Проверено
            // замером scrollWidth — на 0.082 все пять держат по две строки.
            fontSize: format.width * 0.082,
            fontWeight: 600,
            color: ink,
            lineHeight: 1.05,
            letterSpacing: "-0.02em",
            margin: 0,
          }}
        >
          <L lines={s.title} />
        </h1>
        {/* Фиксированный отступ, а не распорка flex:1: та прижимала
            подзаголовок к низу шапки, и зазор гулял от слайда к слайду
            в зависимости от высоты заголовка. */}
        <p
          style={{
            fontFamily: SANS,
            fontSize: format.width * 0.056,
            fontWeight: 400,
            color: muted,
            margin: `${format.width * 0.042}px 0 0`,
            lineHeight: 1.4,
          }}
        >
          <L lines={s.subtitle} />
        </p>
      </div>

      <div style={{ flex: 1, position: "relative" }}>
        <Phone
          src={screenshotUrl(locale, s.screenshot)}
          alt={s.label}
          width={format.width * format.phoneWidthRatio}
          style={{
            position: "absolute",
            bottom: 0,
            left: "50%",
            transform: `translateX(-50%) translateY(${format.phoneTranslateY}%)`,
          }}
        />
      </div>
    </div>
  );
}

/* ── Превью ────────────────────────────────────────────────────────────── */

function Preview({
  s,
  locale,
  index,
  format,
  onExport,
}: {
  s: LocaleSlide;
  locale: string;
  index: number;
  format: StoreFormat;
  onExport: (id: string) => void;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(0.15);

  useEffect(() => {
    const node = ref.current;
    if (!node) return;
    const ro = new ResizeObserver(() =>
      setScale(node.getBoundingClientRect().width / format.width),
    );
    ro.observe(node);
    return () => ro.disconnect();
  }, [format.width]);

  return (
    <div>
      <div
        ref={ref}
        onClick={() => onExport(s.id)}
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
          <SlideView s={s} locale={locale} format={format} />
        </div>
      </div>
      <p style={{ textAlign: "center", fontSize: 12, color: "#888", margin: "7px 0 0" }}>
        {index + 1}. {s.label}
      </p>
    </div>
  );
}

/* ── Страница ──────────────────────────────────────────────────────────── */

export default function Page() {
  const [content, setContent] = useState<LoadedContent | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [requestedLocale, setRequestedLocale] = useState<string | null | undefined>(
    undefined,
  );
  const [busy, setBusy] = useState<string | null>(null);
  const [exportError, setExportError] = useState<string | null>(null);
  const [formatIdx, setFormatIdx] = useState(0);
  const [capture, setCapture] = useState<{
    slideId: string;
    formatId: string;
  } | null>(null);
  const offRefs = useRef<Record<string, HTMLDivElement | null>>({});
  const format = content?.formats[formatIdx];

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

  useEffect(() => {
    if (!content) return;
    setCapture(
      captureMode(
        window.location.search,
        content.slides.map((slide) => slide.id),
        content.formats.map((item) => item.id),
      ),
    );
  }, [content]);

  if (loadError) {
    return <p role="alert">Ошибка конфигурации: {loadError}</p>;
  }

  if (!content || !format) {
    return <p>Загружаю конфигурацию…</p>;
  }

  const loadedContent = content;
  const selectedFormat = format;

  if (capture) {
    const slide = content.slides.find((item) => item.id === capture.slideId);
    const captureFormat = content.formats.find(
      (item) => item.id === capture.formatId,
    );

    if (slide && captureFormat) {
      return (
        <div
          style={{
            position: "fixed",
            inset: 0,
            overflow: "hidden",
          }}
        >
          <SlideView s={slide} locale={content.locale} format={captureFormat} />
        </div>
      );
    }
  }

  function changeLocale(locale: string) {
    const url = new URL(window.location.href);
    url.searchParams.set("locale", locale);
    window.history.replaceState(null, "", url);
    setRequestedLocale(locale);
  }

  async function renderBlob(id: string, el: HTMLDivElement) {
    // Снимать за краем вьюпорта html-to-image не умеет — на время съёмки
    // выводим узел на экран под остальным содержимым.
    el.style.left = "0px";
    el.style.opacity = "1";
    el.style.zIndex = "-1";

    try {
      await Promise.all(
        Array.from(el.querySelectorAll("img")).map((img) =>
          img.complete
            ? Promise.resolve()
            : new Promise<void>((r) => {
                img.onload = () => r();
                img.onerror = () => r();
              }),
        ),
      );
      await new Promise((r) => setTimeout(r, 400));
      console.log(`[${id}] картинки готовы`);

      // pixelRatio вместо даунскейла канвасом: рендер сразу в целевом
      // разрешении, без потери резкости на тексте.
      const opts = {
        width: selectedFormat.width,
        height: selectedFormat.height,
        pixelRatio: 1,
        cacheBust: true,
      };
      // Первый вызов прогревает шрифты и картинки, чистый кадр даёт второй.
      await withTimeout(toPng(el, opts), EXPORT_TIMEOUT_MS, `${id}, прогрев`);
      console.log(`[${id}] прогрев ок`);
      await new Promise((r) => setTimeout(r, 150));
      const url = await withTimeout(toPng(el, opts), EXPORT_TIMEOUT_MS, id);
      console.log(`[${id}] снято, ${Math.round(url.length / 1024)}КБ`);

      const img = new window.Image();
      img.src = url;
      // decode() честно реджектится на битой картинке; onload без onerror
      // подвешивал экспорт навсегда.
      await img.decode();

      const cv = document.createElement("canvas");
      cv.width = selectedFormat.width;
      cv.height = selectedFormat.height;
      cv.getContext("2d")!.drawImage(
        img,
        0,
        0,
        selectedFormat.width,
        selectedFormat.height,
      );

      const idx = loadedContent.slides.findIndex((s) => s.id === id);
      const name = `${String(idx + 1).padStart(2, "0")}-${id}-${selectedFormat.width}x${selectedFormat.height}.png`;
      const blob = await new Promise<Blob>((res) =>
        cv.toBlob((b) => res(b!), "image/png"),
      );
      console.log(`[${id}] готово: ${name}`);
      return { name, blob };
    } finally {
      el.style.left = "-9999px";
      el.style.opacity = "";
      el.style.zIndex = "";
    }
  }

  async function exportOne(id: string) {
    const el = offRefs.current[id];
    if (!el) return;
    setExportError(null);
    setBusy(id);
    try {
      const { name, blob } = await renderBlob(id, el);
      const a = document.createElement("a");
      a.href = URL.createObjectURL(blob);
      a.download = name;
      // Без вставки в документ Chrome глотает повторные программные клики.
      document.body.appendChild(a);
      a.click();
      a.remove();
    } catch (e) {
      console.error("экспорт упал", e);
      setExportError(e instanceof Error ? e.message : "Не удалось экспортировать слайд.");
    } finally {
      setBusy(null);
    }
  }

  async function exportAll() {
    setExportError(null);
    setBusy("all");
    try {
      const zip = new JSZip();
      for (const s of loadedContent.slides) {
        const el = offRefs.current[s.id];
        if (!el) continue;
        setBusy(s.id);
        const { name, blob } = await renderBlob(s.id, el);
        zip.file(name, blob);
      }
      setBusy("all");
      const out = await zip.generateAsync({ type: "blob" });
      const a = document.createElement("a");
      a.href = URL.createObjectURL(out);
      a.download = `lampada-screenshots-${loadedContent.locale}-${selectedFormat.id}-${selectedFormat.width}x${selectedFormat.height}.zip`;
      a.click();
    } catch (e) {
      console.error("экспорт архива упал", e);
      setExportError(e instanceof Error ? e.message : "Не удалось экспортировать архив.");
    } finally {
      setBusy(null);
    }
  }

  return (
    <div style={{ minHeight: "100vh", background: "#111", padding: "32px 24px", fontFamily: SANS }}>
      <div style={{ maxWidth: 1440, margin: "0 auto" }}>
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            marginBottom: 28,
          }}
        >
          <div>
            <h1 style={{ fontSize: 20, fontWeight: 700, color: "#fff", margin: "0 0 3px" }}>
              Лампада — скриншоты магазинов
            </h1>
            <p style={{ fontSize: 12, color: "#666", margin: 0 }}>
              {content.slides.length} слайда · {content.locale.toUpperCase()} · клик по превью — скачать
            </p>
          </div>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            <select
              value={content.locale}
              onChange={(e) => changeLocale(e.target.value)}
              style={{
                background: "#222",
                color: "#fff",
                border: "1px solid #444",
                borderRadius: 8,
                padding: "8px 12px",
                fontSize: 13,
                fontWeight: 600,
                cursor: "pointer",
              }}
            >
              {content.locales.map((locale) => (
                <option key={locale} value={locale}>
                  {locale.toUpperCase()}
                </option>
              ))}
            </select>
            <select
              value={formatIdx}
              onChange={(e) => setFormatIdx(Number(e.target.value))}
              style={{
                background: "#222",
                color: "#fff",
                border: "1px solid #444",
                borderRadius: 8,
                padding: "8px 12px",
                fontSize: 13,
                fontWeight: 600,
                cursor: "pointer",
              }}
            >
              {content.formats.map((item, i) => (
                <option key={item.id} value={i}>
                  {item.label} — {item.width}×{item.height}
                </option>
              ))}
            </select>
            <button
              onClick={exportAll}
              disabled={!!busy}
              style={{
                background: busy ? "#333" : ACCENT,
                color: "#fff",
                border: "none",
                borderRadius: 8,
                padding: "9px 20px",
                fontSize: 13,
                fontWeight: 600,
                cursor: busy ? "not-allowed" : "pointer",
              }}
            >
              {busy === "all" ? "Пакую zip…" : busy ? `${busy}…` : "Скачать все"}
            </button>
          </div>
        </div>

        {exportError && (
          <p style={{ margin: "0 0 20px", color: "#ffb4a9", fontSize: 13 }} role="alert">
            {exportError}
          </p>
        )}

        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fill, minmax(190px, 1fr))",
            gap: 20,
          }}
        >
          {content.slides.map((s, i) => (
            <Preview
              key={s.id}
              s={s}
              locale={content.locale}
              index={i}
              format={format}
              onExport={exportOne}
            />
          ))}
        </div>
      </div>

      {/* Экспортные копии в натуральную величину, за краем вьюпорта */}
      <div style={{ position: "absolute", top: 0, overflow: "hidden" }}>
        {content.slides.map((s) => (
          <div
            key={`off-${s.id}`}
            ref={(el) => {
              offRefs.current[s.id] = el;
            }}
            style={{
              position: "absolute",
              left: "-9999px",
              top: 0,
              width: format.width,
              height: format.height,
            }}
          >
            <SlideView s={s} locale={content.locale} format={format} />
          </div>
        ))}
      </div>
    </div>
  );
}
