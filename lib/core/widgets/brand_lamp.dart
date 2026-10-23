import 'package:flutter/material.dart';

/// Марка приложения — та же лампада, что на иконке.
///
/// Заменила абстрактный огонёк, который на 18 логических пикселях
/// вырождался в золотой кружок и ничего не говорил.
///
/// Картинка, а не векторная отрисовка: стекло, крышка и свечение кодом
/// обошлись бы в сотню строк ради статичного изображения. Исходник — та же
/// прозрачная лампада, что на карточке серии, обрезанная по краю свечения:
/// высота марки задаёт размер самой лампады, а не пустых полей.
class BrandLamp extends StatelessWidget {
  const BrandLamp({required this.height, super.key});

  /// Высота в логических пикселях. Ширина считается из пропорций исходника.
  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/lampada.png',
    height: height,
    // Исходник в разы крупнее любого показа, и без фильтрации при уменьшении
    // тонкие контуры креста рябят.
    filterQuality: FilterQuality.medium,
    excludeFromSemantics: true,
  );
}
