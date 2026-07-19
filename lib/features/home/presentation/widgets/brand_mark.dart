// lib/features/home/presentation/widgets/brand_mark.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../daily_cards/presentation/widgets/streak_flame.dart';

/// Огонёк + «Лампада». Общий Hero-тег между [SplashScreen] и [HomeScreen] —
/// при переходе между ними это не фейд, а плавный перелёт на новую позицию.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'brand-mark',
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StreakFlame(size: 18),
            const SizedBox(height: 24),
            Text(
              'Лампада',
              style: AppTheme.quoteStyle(context).copyWith(fontSize: 36),
            ),
          ],
        ),
      ),
    );
  }
}
