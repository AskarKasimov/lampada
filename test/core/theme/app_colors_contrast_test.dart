import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_colors.dart';

/// Относительная яркость по WCAG 2.1.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  /// Текстовые роли и кегль, которым они реально рисуются. Порог AA для
  /// обычного текста — 4.5:1; крупным (>=18pt) хватило бы 3:1, но такого
  /// среди приглушённых ролей нет.
  Map<String, Color> textRoles(AppColorsExtension c) => {
    'ink': c.ink,
    'textSecondary': c.textSecondary,
    'textTertiary': c.textTertiary,
    'homeSubtitle': c.homeSubtitle,
    'todayLabel': c.todayLabel,
    'footer': c.footer,
    'link': c.link,
    'chipUnreadText': c.chipUnreadText,
    'accent': c.accent,
  };

  for (final (name, colors) in [
    ('светлая', AppColorsExtension.light),
    ('тёмная', AppColorsExtension.dark),
  ]) {
    group('$name тема: контраст', () {
      test('весь текст держит WCAG AA (4.5:1)', () {
        final failures = <String>[];
        textRoles(colors).forEach((role, color) {
          final ratio = _contrast(color, colors.background);
          if (ratio < 4.5) {
            failures.add('$role ${ratio.toStringAsFixed(2)}:1');
          }
        });
        expect(failures, isEmpty, reason: 'ниже AA: ${failures.join(", ")}');
      });

      test('надпись на основной кнопке держит AA', () {
        // По §6 это один из двух высококонтрастных элементов приложения.
        // В прошлой палитре он давал 3.06:1 — то есть был самым слабым.
        expect(
          _contrast(colors.background, colors.accent),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('пройденная точка прогресса различима как UI-элемент (3:1)', () {
        // Точки — единственный признак того, на какой карточке юзер стоит.
        expect(
          _contrast(colors.dotDone, colors.background),
          greaterThanOrEqualTo(3.0),
        );
      });

      test('иконки различимы как UI-элемент (3:1)', () {
        expect(
          _contrast(colors.homeIcon, colors.background),
          greaterThanOrEqualTo(3.0),
        );
      });

      test('рамка блока видна', () {
        // Сознательно ниже 3:1 — см. комментарий у chipUnreadBorder. Но
        // прошлые 1.41:1 не были видны вовсе, поэтому нижнюю границу держим.
        expect(
          _contrast(colors.chipUnreadBorder, colors.background),
          greaterThanOrEqualTo(1.6),
        );
      });
    });
  }
}
