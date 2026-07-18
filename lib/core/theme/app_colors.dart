import 'package:flutter/material.dart';

/// Тёплая нейтральная палитра «Лампады». Значения посчитаны из
/// oklch-токенов дизайна (см. docs/superpowers — импорт из claude.ai/design).
abstract final class AppColors {
  static const background = Color(0xFFFAF0E3);
  static const ink = Color(0xFF362418);
  static const textSecondary = Color(0xFF776559);
  static const textTertiary = Color(0xFF89766A);
  static const dotDone = Color(0xFFA99B93);
  static const dotUpcoming = Color(0xFFE0D5CE);
  static const flameLight = Color(0xFFFECE96);

  /// Тёплый янтарный акцент: тёмный конец огонька лампадки и фон
  /// кнопки «Дальше».
  static const accent = Color(0xFFBE7C1C);

  // Home-экран и вторичные подписи (посчитаны из oklch-токенов дизайна).
  static const homeSubtitle = Color(0xFF806D61);
  static const todayLabel = Color(0xFF7B6F67);
  static const footer = Color(0xFF8A7D75);
  static const link = Color(0xFF84776F);
  static const homeIcon = Color(0xFF554438);
  static const chipUnreadText = Color(0xFF887E78);
  static const chipUnreadBorder = Color(0xFFD6CBC5);
}
