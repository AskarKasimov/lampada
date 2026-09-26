import 'package:flutter/material.dart';

/// Общие поля экранов; внутренние отступы компонентов задаются отдельно.
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({this.screenInset = 16, this.dayEntryInset = 20});

  final double screenInset;

  /// У материалов дня поля шире, чем у названия дня и остальных экранов.
  final double dayEntryInset;

  /// Место для метки в заголовке и панели прогресса слева в читалке.
  static const unreadGutter = 13.0;

  static AppSpacing of(BuildContext context) =>
      Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();

  EdgeInsets get horizontal => EdgeInsets.symmetric(horizontal: screenInset);

  EdgeInsets get dayEntryHorizontal =>
      EdgeInsets.symmetric(horizontal: dayEntryInset);

  EdgeInsets get readerPadding =>
      EdgeInsets.fromLTRB(screenInset + unreadGutter, 48, screenInset, 24);

  @override
  AppSpacing copyWith({double? screenInset, double? dayEntryInset}) =>
      AppSpacing(
        screenInset: screenInset ?? this.screenInset,
        dayEntryInset: dayEntryInset ?? this.dayEntryInset,
      );

  @override
  AppSpacing lerp(covariant AppSpacing? other, double t) => other == null
      ? this
      : AppSpacing(
          screenInset: screenInset + (other.screenInset - screenInset) * t,
          dayEntryInset:
              dayEntryInset + (other.dayEntryInset - dayEntryInset) * t,
        );
}
