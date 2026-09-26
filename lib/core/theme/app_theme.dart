import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Спокойная благородная тема — светлый и тёмный варианты.
abstract final class AppTheme {
  // Material выбирает стрелку по платформе; обе темы сохраняют один набор
  // даже для автоматически созданных AppBar кнопок назад и закрытия.
  static final _actionIcons = ActionIconThemeData(
    backButtonIconBuilder: (_) =>
        const Icon(CupertinoIcons.arrow_left, size: 22),
    closeButtonIconBuilder: (_) => const Icon(CupertinoIcons.xmark, size: 22),
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    actionIconTheme: _actionIcons,
    scaffoldBackgroundColor: AppColorsExtension.light.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColorsExtension.light.accent,
      surface: AppColorsExtension.light.background,
    ),
    extensions: const [AppColorsExtension.light],
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    actionIconTheme: _actionIcons,
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
  /// шрифт.
  static TextStyle quoteStyle(BuildContext context) => TextStyle(
    fontFamily: 'Lora',
    fontSize: 24,
    height: 1.6,
    fontStyle: FontStyle.italic,
    color: AppColorsExtension.of(context).ink,
  );

  /// Евангелие не меняет набор при переходе из карточки в полный текст.
  static TextStyle readingTextStyle(BuildContext context) =>
      quoteStyle(context).copyWith(fontSize: 27, height: 1.5);
}
