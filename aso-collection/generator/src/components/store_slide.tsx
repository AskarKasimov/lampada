import React from "react";

import { screenshotCleanupMaskHeight } from "@/lib/screenshot_cleanup.mjs";
import {
  screenshotUrl,
  type LocaleSlide,
  type StoreFormat,
} from "@/lib/screenshot_config";

const CREAM = "#FAF0E3";
const INK = "#362418";
const MUTED = "#776559";
const DARK_BG = "#1E1712";
const DARK_INK = "#F2E6D8";
const DARK_MUTED = "#C9B8A8";

const SERIF = "var(--font-lora), Georgia, serif";
const SANS = "var(--font-inter), -apple-system, system-ui, sans-serif";

const MK_W = 1022;
const MK_H = 2082;
const SC_L = (52 / MK_W) * 100;
const SC_T = (46 / MK_H) * 100;
const SC_W = (918 / MK_W) * 100;
const SC_H = (1990 / MK_H) * 100;
const SC_RX = (126 / 918) * 100;
const SC_RY = (126 / 1990) * 100;

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

function Phone({ src, alt, width }: { src: string; alt: string; width: number }) {
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
        <StatusBar screenW={screenW} />
      </div>
    </div>
  );
}

export function StoreSlide({
  slide,
  locale,
  format,
}: {
  slide: LocaleSlide;
  locale: string;
  format: StoreFormat;
}) {
  const dark = slide.theme === "dark";
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
            fontSize: format.width * 0.082,
            fontWeight: 600,
            color: ink,
            lineHeight: 1.05,
            letterSpacing: "-0.02em",
            margin: 0,
          }}
        >
          <Lines lines={slide.title} />
        </h1>
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
          <Lines lines={slide.subtitle} />
        </p>
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
          />
        </div>
      </div>
    </div>
  );
}
