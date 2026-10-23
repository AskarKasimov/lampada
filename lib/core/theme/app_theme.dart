import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Спокойная благородная тема — светлый и тёмный варианты.
abstract final class AppTheme {
  // Material выбирает стрелку по платформе; обе темы сохраняют один набор
  // даже для автоматически созданных AppBar кнопок назад и закрытия.
  static final _actionIcons = ActionIconThemeData(
    backButtonIconBuilder: (_) =>
        const Icon(CupertinoIcons.arrow_left, size: 22),
    closeButtonIconBuilder: (_) => const Icon(CupertinoIcons.xmark, size: 22),
  );

  /// Типографика Material 3 без её разрядки (+0.25…0.5 у основного текста
  /// и подписей): с ней подписи выглядели рыхлыми и спорили с Lora. Разрядку Flutter подмешивает при
  /// локализации темы, поэтому убирать её нужно в геометрии типографики,
  /// а не в textTheme.
  static Typography get _typography {
    final base = Typography.material2021(platform: defaultTargetPlatform);
    return base.copyWith(
      englishLike: _withoutTracking(base.englishLike),
      dense: _withoutTracking(base.dense),
      tall: _withoutTracking(base.tall),
    );
  }

  static TextTheme _withoutTracking(TextTheme theme) {
    TextStyle? tight(TextStyle? style) => style?.copyWith(letterSpacing: 0);
    return theme.copyWith(
      displayLarge: tight(theme.displayLarge),
      displayMedium: tight(theme.displayMedium),
      displaySmall: tight(theme.displaySmall),
      headlineLarge: tight(theme.headlineLarge),
      headlineMedium: tight(theme.headlineMedium),
      headlineSmall: tight(theme.headlineSmall),
      titleLarge: tight(theme.titleLarge),
      titleMedium: tight(theme.titleMedium),
      titleSmall: tight(theme.titleSmall),
      bodyLarge: tight(theme.bodyLarge),
      bodyMedium: tight(theme.bodyMedium),
      bodySmall: tight(theme.bodySmall),
      labelLarge: tight(theme.labelLarge),
      labelMedium: tight(theme.labelMedium),
      labelSmall: tight(theme.labelSmall),
    );
  }

  /// Шрифт подписей, кнопок, вкладок и AppBar. Lora задаётся явно в
  /// [quoteStyle] и [headingStyle].
  static const _uiFontFamily = 'PT Sans';

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: _uiFontFamily,
    typography: _typography,
    actionIconTheme: _actionIcons,
    appBarTheme: AppBarThemeData(titleSpacing: const AppSpacing().screenInset),
    scaffoldBackgroundColor: AppColorsExtension.light.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColorsExtension.light.accent,
      surface: AppColorsExtension.light.background,
    ),
    extensions: const [AppColorsExtension.light, AppSpacing()],
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    fontFamily: _uiFontFamily,
    typography: _typography,
    actionIconTheme: _actionIcons,
    appBarTheme: AppBarThemeData(titleSpacing: const AppSpacing().screenInset),
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColorsExtension.dark.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColorsExtension.dark.accent,
      brightness: Brightness.dark,
      surface: AppColorsExtension.dark.background,
    ),
    extensions: const [AppColorsExtension.dark, AppSpacing()],
  );

  /// Прямой serif Lora для текста чтения и названий. В приложении две
  /// гарнитуры: Lora для того, что читают и называют (тексты, заголовки,
  /// названия плиток, крупные числа), PT Sans для подписей и управления. Курсив убран: рядом с прямыми заголовками он спорил с ними,
  /// а длинный текст прямым начертанием читается легче.
  static TextStyle quoteStyle(BuildContext context) => TextStyle(
    fontFamily: 'Lora',
    fontSize: 24,
    height: 1.6,
    color: AppColorsExtension.of(context).ink,
  );

  /// Заголовки экранов и шторок, крупные числа: та же Lora, плотнее строки.
  /// Одно начертание без полужирного: вес Lora Regular держит иерархию
  /// размером, а синтетический жирный Flutter рисует грубо.
  static TextStyle headingStyle(BuildContext context, {double fontSize = 26}) =>
      quoteStyle(context).copyWith(fontSize: fontSize, height: 1.2);

  /// Кегль названий карточек главной: «Стих дня», плитки дня и курса.
  /// Небольшой, чтобы главными на плитках были иллюстрации.
  static const cardTitleSize = 19.0;

  /// Название карточки главной. Один стиль на все карточки, чтобы под
  /// заголовком «Сегодня» не набиралось разных шрифтов.
  static TextStyle cardTitleStyle(BuildContext context) =>
      headingStyle(context, fontSize: cardTitleSize).copyWith(height: 1.15);

  /// Мелкая подпись под названием карточки: ссылка стиха, счётчик курса.
  static TextStyle cardCaptionStyle(BuildContext context) => TextStyle(
    fontSize: 13,
    height: 1.2,
    color: AppColorsExtension.of(context).textSecondary,
  );

  /// Евангелие не меняет набор при переходе из карточки в полный текст.
  static TextStyle readingTextStyle(BuildContext context) =>
      quoteStyle(context).copyWith(fontSize: 27, height: 1.5);
}
