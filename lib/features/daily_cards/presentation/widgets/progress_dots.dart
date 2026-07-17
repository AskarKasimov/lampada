import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Ряд точек-индикаторов прогресса по карточкам дня: пройденные — тусклые,
/// текущая — крупная и в цвете своего типа, будущие — едва заметные.
class ProgressDots extends StatelessWidget {
  const ProgressDots({
    super.key,
    required this.count,
    required this.currentIndex,
    required this.accentColors,
  });

  final int count;
  final int currentIndex;

  /// Акцентный цвет активной точки — свой для каждой позиции (по типу карточки).
  final List<Color> accentColors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i != 0) const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: i == currentIndex ? 8 : 6,
            height: i == currentIndex ? 8 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == currentIndex
                  ? accentColors[i]
                  : (i < currentIndex
                      ? AppColors.dotDone
                      : AppColors.dotUpcoming),
            ),
          ),
        ],
      ],
    );
  }
}
