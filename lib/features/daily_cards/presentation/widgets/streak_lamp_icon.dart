import 'package:flutter/material.dart';

const streakLampOnAsset = 'assets/illustrations/lampada_on.png';
const streakLampOffAsset = 'assets/illustrations/lampada_off.png';

/// Маленькая лампада серии: горит, пока серия жива. Те же ассеты, что у
/// большой лампады итога «Мудрости дня», чтобы знак серии был один.
class StreakLampIcon extends StatelessWidget {
  const StreakLampIcon({required this.lit, required this.size, super.key});

  final bool lit;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    // Сама лампада занимает около двух третей холста иллюстрации, остальное
    // прозрачное поле и свечение. Масштаб на раскладку не влияет.
    child: Transform.scale(
      scale: 1.5,
      child: Image.asset(
        lit ? streakLampOnAsset : streakLampOffAsset,
        excludeFromSemantics: true,
        // Исходник 1024 px: без фильтрации при уменьшении контуры рябят.
        filterQuality: FilterQuality.medium,
      ),
    ),
  );
}
