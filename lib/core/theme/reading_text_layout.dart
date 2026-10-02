import 'package:flutter/material.dart';

import '../format/content_preview.dart';
import 'reading_font_size.dart';

typedef ReadingTextLayout = ({
  String text,
  double fontSize,
  bool needsFullText,
});

/// Сначала пробуем весь материал. Превью появляется только после исчерпания
/// ступеней; системный масштаб при этом не компенсируется уменьшением кегля.
ReadingTextLayout readingTextLayout({
  required BuildContext context,
  required String text,
  required TextStyle style,
  required double maxWidth,
  required double maxHeight,
  required double scaledMaxHeight,
  double previewExtraHeight = 0,
}) {
  final size = readingFontSize(
    context: context,
    text: text,
    style: style,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
  );
  final scaledStyle = style.copyWith(fontSize: size);
  final scaler = MediaQuery.textScalerOf(context);
  bool fits(String value, TextStyle candidate, {double? height}) =>
      readingTextHeight(
        context: context,
        text: value,
        style: candidate,
        maxWidth: maxWidth,
        textScaler: scaler,
      ) <=
      (height ?? scaledMaxHeight);
  if (fits(text, scaledStyle)) {
    return (text: text, fontSize: size, needsFullText: false);
  }

  final previewStyle = style.copyWith(fontSize: size);
  // Лимит остаётся верхней границей превью. На маленьком экране или при
  // крупном системном шрифте сокращаем его дальше, сохраняя вертикальный свайп.
  final characters = text.characters;
  var low = 0;
  var high = characters.length.clamp(0, contentPreviewLength);
  while (low < high) {
    final middle = (low + high + 1) ~/ 2;
    if (fits(
      '${characters.take(middle)}…',
      previewStyle,
      height: scaledMaxHeight - previewExtraHeight,
    )) {
      low = middle;
    } else {
      high = middle - 1;
    }
  }
  return (
    text: '${characters.take(low)}…',
    fontSize: size,
    needsFullText: true,
  );
}
