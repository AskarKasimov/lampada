import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Прогресс по отрывку волосяной линией (FR-008). Именно линия, а не точки:
/// стихов в отрывке бывает под сорок, и точки превратились бы в рябь.
class ReadingProgressLine extends StatelessWidget {
  const ReadingProgressLine({
    super.key,
    required this.position,
    required this.total,
  });

  /// Индекс текущей страницы, от нуля.
  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final progress = total <= 1 ? 1.0 : (position + 1) / total;

    return Semantics(
      label: 'Стих ${position + 1} из $total',
      child: SizedBox(
        height: 1,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Container(color: colors.chipUnreadBorder),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: constraints.maxWidth * progress,
                color: colors.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
