import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Ненавязчиво объясняет единственный способ перейти к следующей карточке.
class CardSwipeHint extends StatelessWidget {
  const CardSwipeHint({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.arrow_back, size: 16, color: colors.homeSubtitle),
        const SizedBox(width: 6),
        Text(
          'Свайпните влево',
          style: TextStyle(fontSize: 12, color: colors.homeSubtitle),
        ),
      ],
    );
  }
}
