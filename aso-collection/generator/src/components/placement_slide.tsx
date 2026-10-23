import React from "react";

import { CREAM, INK, Phone, SERIF } from "@/components/store_slide";
import type { LoadedPlacement } from "@/lib/screenshot_content";
import { screenshotUrl } from "@/lib/screenshot_config";
import { MOCKUP_HEIGHT, MOCKUP_WIDTH, TITLE_LINE_HEIGHT, fitFontSize } from "@/lib/title_layout";

const GLOW = "rgba(242, 178, 92, 0.38)";
// Цвет креста на плитке «Мудрость дня» в светлой теме приложения.
const CROSS = "#E8CBA5";

// Восьмиконечный крест той же геометрии, что OrthodoxCross в приложении:
// нижняя перекладина поднята левым от зрителя концом.
function OrthodoxCross({ size, color }: { size: number; color: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" style={{ display: "block" }}>
      <path
        d="M50 8V94M38 22H62M20 38H80M36 67L64 78"
        fill="none"
        stroke={color}
        strokeWidth={6.5}
        strokeLinecap="round"
      />
    </svg>
  );
}

function CrossMark({ x, y, size }: { x: number; y: number; size: number }) {
  return (
    // Под заголовком крест приглушён сильнее, чем на плитке: иначе спорит с текстом.
    <div style={{ position: "absolute", left: x - size / 2, top: y - size / 2, opacity: 0.6 }}>
      <OrthodoxCross size={size} color={CROSS} />
    </div>
  );
}

function Title({
  lines,
  size,
  align,
}: {
  lines: string[];
  size: number;
  align: "left" | "center";
}) {
  return (
    <h1
      style={{
        fontFamily: SERIF,
        fontSize: size,
        fontWeight: 700,
        color: INK,
        lineHeight: TITLE_LINE_HEIGHT,
        letterSpacing: "-0.01em",
        textAlign: align,
        margin: 0,
        whiteSpace: "nowrap",
      }}
    >
      {lines.map((line, index) => (
        <React.Fragment key={index}>
          {index > 0 && <br />}
          {line}
        </React.Fragment>
      ))}
    </h1>
  );
}

// Шапка страницы: только крупный заголовок. По высоте он в безопасной
// зоне, а по ширине занимает центральные 52% холста: iPhone показывает
// шапку на всю высоту и около 65% ширины, формальная зона Apple (43%)
// делала текст вдвое мельче. Лампаду не рисуем: она повторяла иконку
// прямо под шапкой.
const HEADER_TEXT_WIDTH = 0.52;

function TitleLayout({ placement }: { placement: LoadedPlacement }) {
  const safe = placement.safeArea;
  const width = placement.width * HEADER_TEXT_WIDTH;
  const size = fitFontSize(placement.title, width, safe.height);
  return (
    <>
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `radial-gradient(ellipse ${width * 0.75}px ${safe.height * 1.4}px at 50% ${safe.y + safe.height / 2}px, ${GLOW}, transparent)`,
        }}
      />
      <CrossMark x={placement.width / 2} y={safe.y + safe.height / 2} size={placement.height * 1.15} />
      <div
        style={{
          position: "absolute",
          left: (placement.width - width) / 2,
          top: safe.y,
          width,
          height: safe.height,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <Title lines={placement.title} size={size} align="center" />
      </div>
    </>
  );
}

// Выдача поиска: ряд наклонённых телефонов на весь холст, чтобы креатив
// не пустовал при любой обрезке. Заголовок по центру безопасной зоны на
// кремовой подложке, которая гасит экраны под текстом.
function PhonesLayout({ placement, locale }: { placement: LoadedPlacement; locale: string }) {
  const safe = placement.safeArea;
  const size = fitFontSize(placement.title, safe.width * 0.92, safe.height * 0.62);
  const phoneWidth = placement.width * 0.24;
  const phoneHeight = phoneWidth * (MOCKUP_HEIGHT / MOCKUP_WIDTH);
  const pitch = phoneWidth * 1.08;
  const count = placement.screenshots.length;
  const centerX = placement.width / 2;
  const centerY = safe.y + safe.height / 2;
  return (
    <>
      <div
        style={{
          position: "absolute",
          inset: 0,
          transform: "rotate(-6deg)",
          transformOrigin: `${centerX}px ${centerY}px`,
        }}
      >
        {placement.screenshots.map((screenshot, index) => {
          const offset = index - (count - 1) / 2;
          // Соседние телефоны сдвинуты по вертикали, ряд не выглядит забором.
          const shift = (index % 2 === 0 ? -1 : 1) * phoneHeight * 0.12;
          return (
            <div
              key={`${screenshot}-${index}`}
              style={{
                position: "absolute",
                left: centerX + offset * pitch - phoneWidth / 2,
                top: centerY - phoneHeight / 2 + shift,
                width: phoneWidth,
                height: phoneHeight,
              }}
            >
              <Phone src={screenshotUrl(locale, screenshot)} alt="" width={phoneWidth} dark={false} />
            </div>
          );
        })}
      </div>
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `radial-gradient(ellipse ${safe.width * 0.66}px ${safe.height * 0.8}px at ${centerX}px ${centerY}px, ${CREAM} 62%, rgba(250, 240, 227, 0) 100%)`,
        }}
      />
      <div
        style={{
          position: "absolute",
          left: safe.x,
          top: safe.y,
          width: safe.width,
          height: safe.height,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <Title lines={placement.title} size={size} align="center" />
      </div>
    </>
  );
}

export function PlacementSlide({
  placement,
  locale,
}: {
  placement: LoadedPlacement;
  locale: string;
}) {
  return (
    <div
      style={{
        position: "relative",
        width: placement.width,
        height: placement.height,
        background: CREAM,
        overflow: "hidden",
      }}
    >
      {placement.layout === "title" ? (
        <TitleLayout placement={placement} />
      ) : (
        <PhonesLayout placement={placement} locale={locale} />
      )}
    </div>
  );
}
