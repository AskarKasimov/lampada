import 'package:flutter/material.dart';

/// Марка приложения — та же лампада, что на иконке.
///
/// Заменила абстрактный огонёк [StreakFlame], который на 18 логических
/// пикселях вырождался в золотой кружок и ничего не говорил. Огонёк остался
/// там, где он и осмыслен: точкой активности в полоске недели, где на предмет
/// всё равно не хватило бы места.
///
/// Картинка, а не векторная отрисовка: силуэт лампады — ажур, чаша, цепи —
/// кодом обошёлся бы в сотню строк ради статичного изображения.
class BrandLamp extends StatelessWidget {
  const BrandLamp({required this.height, super.key});

  /// Высота в логических пикселях. Ширина считается из пропорций исходника.
  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/lampada.png',
    height: height,
    // Исходник в разы крупнее любого показа, и без фильтрации при уменьшении
    // тонкие цепи рябят.
    filterQuality: FilterQuality.medium,
    excludeFromSemantics: true,
  );
}
