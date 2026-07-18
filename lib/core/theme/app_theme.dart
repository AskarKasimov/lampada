import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Спокойная благородная тема — светлый и тёмный варианты.
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColorsExtension.light.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColorsExtension.light.accent,
          surface: AppColorsExtension.light.background,
        ),
        extensions: const [AppColorsExtension.light],
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColorsExtension.dark.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColorsExtension.dark.accent,
          brightness: Brightness.dark,
          surface: AppColorsExtension.dark.background,
        ),
        extensions: const [AppColorsExtension.dark],
      );

  /// Курсивный serif (шрифт-ассет Lora-Italic.ttf) для цитаты/мысли дня —
  /// единственное место, где используется Lora, остальной UI — системный
  /// шрифт. Цвет берётся из палитры активной темы.
  static TextStyle quoteStyle(BuildContext context) => TextStyle(
        fontFamily: 'Lora',
        fontSize: 24,
        height: 1.6,
        fontStyle: FontStyle.italic,
        color: AppColorsExtension.of(context).ink,
      );
}
