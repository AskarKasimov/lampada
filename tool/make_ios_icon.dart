import 'dart:io';

import 'package:image/image.dart' as img;

/// Готовит iOS-иконку из прозрачного исходника.
///
/// Зачем отдельный шаг, а не `remove_alpha_ios` из flutter_launcher_icons:
/// в исходнике под `alpha = 0` лежит произвольный RGB (обычное дело для
/// картинок из генераторов — там зелень). Пакет альфу не композитит, а просто
/// выставляет её в 255, и этот мусор вылезает наружу: под огоньком получалась
/// ярко-зелёная клякса и зелёная крошка по всему полю.
///
/// Здесь исходник честно накладывается на плашку фона, и на выходе PNG вообще
/// без альфа-канала — ломать пакету больше нечего.
///
/// Запуск: dart run tool/make_ios_icon.dart
void main() {
  const source = 'assets/icon/icon_foreground.png';
  const target = 'assets/icon/icon_ios.png';

  // Средний тёплый коричневый — тон иконной доски.
  //
  // Обе крайности пробовали и обе плохи. Тёмный фон приложения (#1E1712) в
  // православном контексте читается траурно. Светлый (#FAF0E3) даёт с золотым
  // огоньком контраст ~1.8:1 — в сетке иконок огонёк на нём пропадает.
  // Здесь ~4.4:1: огонёк виден, поле остаётся деревом, а не чёрным.
  final background = img.ColorRgb8(0x5C, 0x48, 0x38);

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
