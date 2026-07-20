import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lampada_mark.dart';

/// Лампада + «Лампада». Используется там, где сцена красного угла не
/// разворачивается: splash, экран загрузки, офлайн-вид.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.heroTag});

  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LampadaMark(size: 22, heroTag: heroTag),
        const SizedBox(height: 24),
        Text(
          'Лампада',
          style: AppTheme.quoteStyle(context).copyWith(fontSize: 36),
        ),
      ],
    );
  }
}
