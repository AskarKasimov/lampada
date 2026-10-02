import 'package:flutter/material.dart';

/// Ступени проверяются без системного масштаба: увеличение для доступности
/// должно увеличивать текст, а не заставлять выбирать меньший кегль.
double readingFontSize({
  required BuildContext context,
  required String text,
  required TextStyle style,
  required double maxWidth,
  required double maxHeight,
}) {
  for (final size in [27.0, 24.0, 22.0, 20.0]) {
    if (readingTextHeight(
          context: context,
          text: text,
          style: style.copyWith(fontSize: size),
          maxWidth: maxWidth,
        ) <=
        maxHeight) {
      return size;
    }
  }
  return 20;
}

/// Учитываем тот же унаследованный стиль и переносы, что и у Text.
double readingTextHeight({
  required BuildContext context,
  required String text,
  required TextStyle style,
  required double maxWidth,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  var effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
  if (MediaQuery.boldTextOf(context)) {
    effectiveStyle = effectiveStyle.copyWith(fontWeight: FontWeight.bold);
  }
  final painter = TextPainter(
    text: TextSpan(text: text, style: effectiveStyle),
    textScaler: textScaler,
    textDirection: Directionality.of(context),
    textAlign: TextAlign.center,
    locale: Localizations.maybeLocaleOf(context),
  )..layout(maxWidth: maxWidth);
  final height = painter.height;
  painter.dispose();
  return height;
}
