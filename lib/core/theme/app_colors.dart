import 'package:flutter/material.dart';

/// Тёплая нейтральная палитра «Лампады» — по одному инстансу на тему.
/// Значения посчитаны из oklch-токенов дизайна (см. docs/superpowers —
/// импорт из claude.ai/design).
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.background,
    required this.ink,
    required this.textSecondary,
    required this.textTertiary,
    required this.dotDone,
    required this.dotUpcoming,
    required this.flameLight,
    required this.accent,
    required this.homeSubtitle,
    required this.todayLabel,
    required this.footer,
    required this.link,
    required this.homeIcon,
    required this.chipUnreadText,
    required this.chipUnreadBorder,
    required this.homeButtonBackground,
  });

  final Color background;
  final Color ink;
  final Color textSecondary;
  final Color textTertiary;
  final Color dotDone;
  final Color dotUpcoming;
  final Color flameLight;

  /// Тёплый янтарный акцент: тёмный конец огонька лампадки и фон
  /// кнопки «Дальше».
  final Color accent;

  // Home-экран и вторичные подписи (посчитаны из oklch-токенов дизайна).
  final Color homeSubtitle;
  final Color todayLabel;
  final Color footer;
  final Color link;
  final Color homeIcon;
  final Color chipUnreadText;
  final Color chipUnreadBorder;

  /// Фон круглой кнопки «на главный экран» — еле заметный тонированный
  /// круг, не заявленный в дизайн-токенах отдельно. Раньше был хардкодом
  /// `Colors.black.withValues(alpha: 0.05)` прямо в виджете; на тёмном фоне
  /// чёрный на 5% почти не виден, поэтому на dark используем белый той же
  /// логики «еле заметно».
  final Color homeButtonBackground;

  static const light = AppColorsExtension(
    background: Color(0xFFFAF0E3),
    ink: Color(0xFF362418),
    textSecondary: Color(0xFF776559),
    textTertiary: Color(0xFF89766A),
    dotDone: Color(0xFFA99B93),
    dotUpcoming: Color(0xFFE0D5CE),
    flameLight: Color(0xFFFECE96),
    accent: Color(0xFFBE7C1C),
    homeSubtitle: Color(0xFF806D61),
    todayLabel: Color(0xFF7B6F67),
    footer: Color(0xFF8A7D75),
    link: Color(0xFF84776F),
    homeIcon: Color(0xFF554438),
    chipUnreadText: Color(0xFF887E78),
    chipUnreadBorder: Color(0xFFD6CBC5),
    homeButtonBackground: Color(0x0D000000),
  );

  /// Тёплый тёмно-коричневый фон («комната при свече ночью»), не
  /// чёрно-серая тема — сохраняет идентичность светлой палитры.
  static const dark = AppColorsExtension(
    background: Color(0xFF1E1712),
    ink: Color(0xFFF2E6D8),
    textSecondary: Color(0xFFC9B8A8),
    textTertiary: Color(0xFFA6937F),
    dotDone: Color(0xFF8C7A6C),
    dotUpcoming: Color(0xFF3A2F26),
    flameLight: Color(0xFFFFD9A0),
    accent: Color(0xFFE0983A),
    homeSubtitle: Color(0xFFB9A794),
    todayLabel: Color(0xFFAE9C89),
    footer: Color(0xFFA6937F),
    link: Color(0xFFA6937F),
    homeIcon: Color(0xFFEFDFCB),
    chipUnreadText: Color(0xFFA79686),
    chipUnreadBorder: Color(0xFF4A3C30),
    homeButtonBackground: Color(0x14FFFFFF),
  );

  /// Палитра активной темы; `light`, если тема её не регистрировала
  /// (например, тестовый `MaterialApp` без явного `theme:`).
  static AppColorsExtension of(BuildContext context) =>
      Theme.of(context).extension<AppColorsExtension>() ?? light;

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? ink,
    Color? textSecondary,
    Color? textTertiary,
    Color? dotDone,
    Color? dotUpcoming,
    Color? flameLight,
    Color? accent,
    Color? homeSubtitle,
    Color? todayLabel,
    Color? footer,
    Color? link,
    Color? homeIcon,
    Color? chipUnreadText,
    Color? chipUnreadBorder,
    Color? homeButtonBackground,
  }) =>
      AppColorsExtension(
        background: background ?? this.background,
        ink: ink ?? this.ink,
        textSecondary: textSecondary ?? this.textSecondary,
        textTertiary: textTertiary ?? this.textTertiary,
        dotDone: dotDone ?? this.dotDone,
        dotUpcoming: dotUpcoming ?? this.dotUpcoming,
        flameLight: flameLight ?? this.flameLight,
        accent: accent ?? this.accent,
        homeSubtitle: homeSubtitle ?? this.homeSubtitle,
        todayLabel: todayLabel ?? this.todayLabel,
        footer: footer ?? this.footer,
        link: link ?? this.link,
        homeIcon: homeIcon ?? this.homeIcon,
        chipUnreadText: chipUnreadText ?? this.chipUnreadText,
        chipUnreadBorder: chipUnreadBorder ?? this.chipUnreadBorder,
        homeButtonBackground:
            homeButtonBackground ?? this.homeButtonBackground,
      );

  @override
  AppColorsExtension lerp(
    ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    return t < 0.5 ? this : other;
  }
}
