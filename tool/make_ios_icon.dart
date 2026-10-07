import 'dart:io';

import 'package:image/image.dart' as img;

/// Композитит прозрачный исходник iOS-иконки на непрозрачный фон.
void main() {
  const source = 'assets/icon/icon_foreground.png';
  const target = 'assets/icon/icon_ios.png';

  // Тот же кремовый, что adaptive_icon_background в pubspec.yaml: на нём
  // тёплое свечение зелёной лампады читается мягко.
  final background = img.ColorRgb8(0xF7, 0xEF, 0xE2);

  final decoded = img.decodePng(File(source).readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('Не удалось прочитать $source');
    exit(1);
  }

  final canvas = img.Image(
    width: decoded.width,
    height: decoded.height,
    numChannels: 3,
  );
  img.fill(canvas, color: background);
  img.compositeImage(canvas, decoded);

  File(target).writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln('$target — ${canvas.width}x${canvas.height}, без альфы');
}
