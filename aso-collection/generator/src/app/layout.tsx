import type { Metadata } from "next";
import { Lora, Inter } from "next/font/google";
import "./globals.css";

// Кириллица обязательна: без сабсета Lora подставит fallback и экспорт
// уедет в другой шрифт.
const lora = Lora({
  subsets: ["latin", "cyrillic"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-lora",
});

const inter = Inter({
  subsets: ["latin", "cyrillic"],
  weight: ["400", "500", "600"],
  variable: "--font-inter",
});

export const metadata: Metadata = {
  title: "Лампада — App Store screenshots",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ru">
      <body className={`${lora.variable} ${inter.variable}`}>{children}</body>
    </html>
  );
}
