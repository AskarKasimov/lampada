"use client";

import React, { useEffect, useRef, useState } from "react";
import { toPng } from "html-to-image";
import JSZip from "jszip";
import { withTimeout } from "../lib/with_timeout.mjs";

/* ── Канва ─────────────────────────────────────────────────────────────── */

// Дизайним в 6.9" — единственный обязательный размер App Store.
const W = 1320;
const H = 2868;
const EXPORT_TIMEOUT_MS = 30_000;

const SIZES = [
  { label: '6.9"', w: 1320, h: 2868 },
  { label: '6.5"', w: 1284, h: 2778 },
] as const;

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

const TEXT_LR = W * 0.08;
const HEAD_TOP = H * 0.055;
const HEAD_MIN = H * 0.235;

/* ── Макет телефона (промеры под mockup.png) ───────────────────────────── */

const MK_W = 1022;
const MK_H = 2082;
const SC_L = (52 / MK_W) * 100;
const SC_T = (46 / MK_H) * 100;
const SC_W = (918 / MK_W) * 100;
const SC_H = (1990 / MK_H) * 100;
const SC_RX = (126 / 918) * 100;
const SC_RY = (126 / 1990) * 100;

const BASE = "/screenshots/ru";

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
    <div
      style={{
        position: "absolute",
        left: 0,
        top: 0,
        width: "100%",
        height: `${5.6}%`,
        background: CREAM,
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        padding: `0 ${screenW * 0.085}px 0 ${screenW * 0.09}px`,
        zIndex: 5,
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

/* ── Тексты ────────────────────────────────────────────────────────────── */

type Slide = {
  id: string;
  label: string;
  h: string[];
  sub: string[];
  src: string;
  alt: string;
  dark?: boolean;
};

// Заголовок продаёт, подзаголовок объясняет конкретикой — без него человек,
// который о приложении ничего не знает, читает одни обещания.
const SLIDES: Slide[] = [
  {
    id: "hero",
    label: "Главный",
    h: ["Православие", "по 5 минут в день."],
    sub: ["Открыл, прочитал, закрыл.", "Непрочитанное не копится."],
    src: `${BASE}/01-today.png`,
    alt: "Сегодня",
  },
  {
    id: "session",
    label: "Сессия дня",
    h: ["Цитата, совет", "и притча."],
    sub: ["Три коротких текста,", "новые каждый день."],
    src: `${BASE}/02-card.png`,
    alt: "Цитата дня",
    dark: true,
  },
  {
    id: "gospel",
    label: "Евангелие",
    h: ["Читайте Евангелие", "с толкованием."],
    sub: ["Стих за стихом —", "с объяснением святых отцов."],
    src: `${BASE}/03-gospel.png`,
    alt: "Евангелие дня",
  },
  {
    id: "course",
    label: "Курс",
    h: ["Курс «Основы веры»", "из 365 тем."],
    sub: ["По одной теме за раз —", "или сколько захотите."],
    src: `${BASE}/04-course.png`,
    alt: "Основы веры",
    dark: true,
  },
  {
    id: "story",
    label: "Память дня",
    h: ["Кого Церковь", "вспоминает сегодня."],
    sub: ["Праздник, святой", "и рассказ о нём."],
    src: `${BASE}/05-story.png`,
    alt: "Рассказ о дне",
  },
];

/* ── Слайд ─────────────────────────────────────────────────────────────── */

function SlideView({ s }: { s: Slide }) {
  const ink = s.dark ? DARK_INK : INK;
  const muted = s.dark ? DARK_MUTED : MUTED;

  return (
    <div
      style={{
        width: W,
        height: H,
        background: s.dark ? DARK_BG : CREAM,
        overflow: "hidden",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <div
        style={{
          padding: `${HEAD_TOP}px ${TEXT_LR}px 0`,
          display: "flex",
          flexDirection: "column",
          minHeight: HEAD_MIN,
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
            fontSize: W * 0.082,
            fontWeight: 600,
            color: ink,
            lineHeight: 1.05,
            letterSpacing: "-0.02em",
            margin: 0,
          }}
        >
          <L lines={s.h} />
        </h1>
        {/* Фиксированный отступ, а не распорка flex:1: та прижимала
            подзаголовок к низу шапки, и зазор гулял от слайда к слайду
            в зависимости от высоты заголовка. */}
        <p
          style={{
            fontFamily: SANS,
            fontSize: W * 0.056,
            fontWeight: 400,
            color: muted,
            margin: `${W * 0.042}px 0 0`,
            lineHeight: 1.4,
          }}
        >
          <L lines={s.sub} />
        </p>
      </div>

      <div style={{ flex: 1, position: "relative" }}>
        <Phone
          src={s.src}
          alt={s.alt}
          width={W * 0.84}
          style={{
            position: "absolute",
            bottom: 0,
            left: "50%",
            transform: "translateX(-50%) translateY(8%)",
          }}
        />
      </div>
    </div>
  );
}

/* ── Превью ────────────────────────────────────────────────────────────── */

function Preview({
  s,
  index,
  onExport,
}: {
  s: Slide;
  index: number;
  onExport: (id: string) => void;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(0.15);

  useEffect(() => {
    const node = ref.current;
    if (!node) return;
    const ro = new ResizeObserver(() =>
      setScale(node.getBoundingClientRect().width / W),
    );
    ro.observe(node);
    return () => ro.disconnect();
  }, []);

  return (
    <div>
      <div
        ref={ref}
        onClick={() => onExport(s.id)}
        title="Кликните, чтобы скачать"
        style={{
          width: "100%",
          aspectRatio: `${W}/${H}`,
          overflow: "hidden",
          borderRadius: 10,
          cursor: "pointer",
          border: "1px solid rgba(255,255,255,0.12)",
        }}
      >
        <div
          style={{
            width: W,
            height: H,
            transform: `scale(${scale})`,
            transformOrigin: "top left",
          }}
        >
          <SlideView s={s} />
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
  const [busy, setBusy] = useState<string | null>(null);
  const [exportError, setExportError] = useState<string | null>(null);
  const [sizeIdx, setSizeIdx] = useState(0);
  const offRefs = useRef<Record<string, HTMLDivElement | null>>({});

  async function renderBlob(id: string, el: HTMLDivElement) {
    const size = SIZES[sizeIdx];

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
        width: W,
        height: H,
        pixelRatio: size.w / W,
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
      cv.width = size.w;
      cv.height = size.h;
      cv.getContext("2d")!.drawImage(img, 0, 0, size.w, size.h);

      const idx = SLIDES.findIndex((s) => s.id === id);
      const name = `${String(idx + 1).padStart(2, "0")}-${id}-${size.w}x${size.h}.png`;
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
      for (const s of SLIDES) {
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
      a.download = `lampada-screenshots-ru-${SIZES[sizeIdx].w}x${SIZES[sizeIdx].h}.zip`;
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
              Лампада — App Store скриншоты
            </h1>
            <p style={{ fontSize: 12, color: "#666", margin: 0 }}>
              {SLIDES.length} слайда · RU · клик по превью — скачать
            </p>
          </div>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            <select
              value={sizeIdx}
              onChange={(e) => setSizeIdx(Number(e.target.value))}
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
              {SIZES.map((s, i) => (
                <option key={s.label} value={i}>
                  {s.label} — {s.w}×{s.h}
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
          {SLIDES.map((s, i) => (
            <Preview key={s.id} s={s} index={i} onExport={exportOne} />
          ))}
        </div>
      </div>

      {/* Экспортные копии в натуральную величину, за краем вьюпорта */}
      <div style={{ position: "absolute", top: 0, overflow: "hidden" }}>
        {SLIDES.map((s) => (
          <div
            key={`off-${s.id}`}
            ref={(el) => {
              offRefs.current[s.id] = el;
            }}
            style={{ position: "absolute", left: "-9999px", top: 0, width: W, height: H }}
          >
            <SlideView s={s} />
          </div>
        ))}
      </div>
    </div>
  );
}
