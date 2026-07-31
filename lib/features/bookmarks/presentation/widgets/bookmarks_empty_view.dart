import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Пустая копилка. Тон приглашающий, без назидания (FR-017): человек ещё
/// ничего не сделал не так, чтобы читать здесь наставление.
class BookmarksEmptyView extends StatelessWidget {
  const BookmarksEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Копилка смыслов пока пуста',
              textAlign: TextAlign.center,
              style: AppTheme.quoteStyle(context).copyWith(fontSize: 20),
            ),
            const SizedBox(height: 12),
            Text(
              'Если мысль или стих откликнутся — сохраните их закладкой, '
              'и они останутся здесь.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: colors.homeSubtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
