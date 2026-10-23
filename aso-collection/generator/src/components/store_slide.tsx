import React from "react";

import { screenshotCleanupMaskHeight } from "@/lib/screenshot_cleanup.mjs";
import {
  screenshotUrl,
  type LocaleSlide,
  type StoreFormat,
  type ZoomRegion,
} from "@/lib/screenshot_config";
import {
  MOCKUP_HEIGHT as MK_H,
  MOCKUP_WIDTH as MK_W,
  TITLE_GAP_RATIO,
  TITLE_LINE_HEIGHT,
  TITLE_SIDE_RATIO,
  TITLE_TOP_RATIO,
  headerHeight,
} from "@/lib/title_layout";

export const CREAM = "#FAF0E3";
export const INK = "#362418";
const DARK_BG = "#1E1712";
const DARK_INK = "#F2E6D8";
// Фон светлой и тёмной темы приложения, замерен по скриншотам: маска
// status bar не даёт шва.
const SCREEN_LIGHT = "#FAF1E4";
const SCREEN_DARK = "#1D1712";

export const SERIF = "var(--font-lora), Georgia, serif";
const SANS = "var(--font-inter), -apple-system, system-ui, sans-serif";

const SC_L = (52 / MK_W) * 100;
const SC_T = (46 / MK_H) * 100;
const SC_W = (918 / MK_W) * 100;
const SC_H = (1990 / MK_H) * 100;
const SC_RX = (126 / 918) * 100;
const SC_RY = (126 / 1990) * 100;
// Отступ карточки увеличения от края слайда в долях его ширины.
const ZOOM_EDGE_RATIO = 0.03;

function Lines({ lines }: { lines: string[] }) {
  return (
    <>
      {lines.map((line, index) => (
        <React.Fragment key={index}>
          {index > 0 && <br />}
          {line}
        </React.Fragment>
      ))}
    </>
  );
}

function StatusBar({
  screenW,
  dark,
  background = dark ? SCREEN_DARK : SCREEN_LIGHT,
}: {
  screenW: number;
  dark: boolean;
  background?: string;
}) {
  const ink = dark ? DARK_INK : INK;
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
          background,
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
            color: ink,
            letterSpacing: "-0.02em",
          }}
        >
          9:41
        </span>
        <div style={{ display: "flex", alignItems: "center", gap: screenW * 0.022 }}>
          <svg width={icon * 1.15} height={icon * 0.8} viewBox="0 0 18 12">
            {[0, 1, 2, 3].map((index) => (
              <rect
                key={index}
                x={index * 4.6}
                y={9 - index * 3}
                width="3"
                height={3 + index * 3}
                rx="1"
                fill={ink}
              />
            ))}
          </svg>
          <svg width={icon * 1.05} height={icon * 0.8} viewBox="0 0 16 12">
            <path d="M8 10.4 6.1 8.3a2.7 2.7 0 0 1 3.8 0L8 10.4Z" fill={ink} />
            <path
              d="M3.6 5.8a6.4 6.4 0 0 1 8.8 0"
              stroke={ink}
              strokeWidth="1.5"
              strokeLinecap="round"
            />
            <path
              d="M5.5 7.8a3.8 3.8 0 0 1 5 0"
              stroke={ink}
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
              stroke={ink}
              strokeOpacity="0.35"
              strokeWidth="1.2"
            />
            <rect x="2.2" y="2.2" width="18.8" height="7.6" rx="1.8" fill={ink} />
            <path
              d="M24.4 4.2v3.6c.9-.3 1.4-.9 1.4-1.8s-.5-1.5-1.4-1.8Z"
              fill={ink}
              fillOpacity="0.35"
            />
          </svg>
        </div>
      </div>
    </>
  );
}

// Крупная копия области экрана поверх телефона по центру той же области,
// чтобы читалась как лупа. По горизонтали прижимается внутрь слайда.
function ZoomCard({
  src,
  region,
  phoneWidth,
  slideWidth,
  dark,
}: {
  src: string;
  region: ZoomRegion;
  phoneWidth: number;
  slideWidth: number;
  dark: boolean;
}) {
  const screenW = phoneWidth * (SC_W / 100);
  const screenH = screenW * (SC_H / SC_W) * (MK_H / MK_W);
  const width = screenW * region.width * region.scale;
  const height = screenH * region.height * region.scale;
  const centerX = phoneWidth * (SC_L / 100) + screenW * (region.x + region.width / 2);
  const centerY =
    phoneWidth * (MK_H / MK_W) * (SC_T / 100) + screenH * (region.y + region.height / 2);
  const pill = region.shape === "pill";
  const phoneLeft = (slideWidth - phoneWidth) / 2;
  const edge = slideWidth * ZOOM_EDGE_RATIO;
  const left = Math.min(
    Math.max(centerX - width / 2, edge - phoneLeft),
    slideWidth - edge - phoneLeft - width,
  );
  return (
    <div
      data-zoom
      style={{
        position: "absolute",
        zIndex: 20,
        left,
        top: centerY - height / 2,
        width,
        height,
        overflow: "hidden",
        borderRadius: pill ? height / 2 : width * 0.05,
        background: pill ? undefined : dark ? SCREEN_DARK : SCREEN_LIGHT,
        boxShadow: "0 40px 90px rgba(54, 36, 24, 0.28), 0 0 0 2px rgba(54, 36, 24, 0.06)",
      }}
    >
      <img
        src={src}
        alt=""
        style={{
          position: "absolute",
          left: -region.x * screenW * region.scale,
          top: -region.y * screenH * region.scale,
          width: screenW * region.scale,
          height: screenH * region.scale,
          objectFit: "cover",
          objectPosition: "top",
        }}
        draggable={false}
      />
    </div>
  );
}

export function Phone({
  src,
  alt,
  width,
  dark,
  statusBarBackground,
  zoom = [],
  slideWidth = width,
}: {
  src: string;
  alt: string;
  width: number;
  dark: boolean;
  statusBarBackground?: string;
  zoom?: ZoomRegion[];
  slideWidth?: number;
}) {
  const screenW = width * (SC_W / 100);
  return (
    <div style={{ position: "relative", aspectRatio: `${MK_W}/${MK_H}`, width }}>
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
        <StatusBar screenW={screenW} dark={dark} background={statusBarBackground} />
      </div>
      {zoom.map((region, index) => (
        <ZoomCard
          key={index}
          src={src}
          region={region}
          phoneWidth={width}
          slideWidth={slideWidth}
          dark={dark}
        />
      ))}
    </div>
  );
}

export function StoreSlide({
  slide,
  locale,
  format,
  titleSize,
}: {
  slide: LocaleSlide;
  locale: string;
  format: StoreFormat;
  titleSize: number;
}) {
  const dark = slide.theme === "dark";
  const ink = dark ? DARK_INK : INK;
  const textLr = format.width * TITLE_SIDE_RATIO;
  const headTop = format.height * TITLE_TOP_RATIO;
  const headGap = format.height * TITLE_GAP_RATIO;

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
          padding: `${headTop}px ${textLr}px ${headGap}px`,
          boxSizing: "border-box",
          display: "flex",
          flexDirection: "column",
          height: headerHeight(format),
          justifyContent: "center",
          flexShrink: 0,
        }}
      >
        <h1
          style={{
            fontFamily: SERIF,
            fontSize: titleSize,
            fontWeight: 700,
            color: ink,
            lineHeight: TITLE_LINE_HEIGHT,
            letterSpacing: "-0.01em",
            textAlign: "center",
            margin: 0,
          }}
        >
          <Lines lines={slide.title} />
        </h1>
      </div>
      <div style={{ flex: 1, position: "relative" }}>
        <div
          style={{
            position: "absolute",
            bottom: 0,
            left: "50%",
            transform: `translateX(-50%) translateY(${format.phoneTranslateY}%)`,
          }}
        >
          <Phone
            src={screenshotUrl(locale, slide.screenshot)}
            alt={slide.label}
            width={format.width * format.phoneWidthRatio}
            dark={slide.screenTheme === "dark"}
            statusBarBackground={slide.statusBarBackground}
            zoom={slide.zoom}
            slideWidth={format.width}
          />
        </div>
      </div>
    </div>
  );
}
