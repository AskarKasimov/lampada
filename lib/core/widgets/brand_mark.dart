import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'brand_lamp.dart';

/// Огонёк + «Лампада». Общий Hero-тег со сплэшем — при переходе с него это не
/// фейд, а плавный перелёт на новую позицию.
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
            const BrandLamp(height: 76),
            const SizedBox(height: 20),
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
