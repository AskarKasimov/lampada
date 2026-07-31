import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/day_card.dart';

/// Чтение дня крупным блоком-героем.
///
/// Постишное Евангелие с толкованием на конкретный стих — единственное, чего
/// нет у других приложений этой полки. А до правки оно лежало последним из
/// пяти одинаковых прямоугольников, то есть самое ценное выглядело как
/// рядовая строка списка. §6 требований разрешает высокий контраст ровно в
/// двух местах, и путь к ценности — одно из них.
class ReadingHeroBlock extends StatelessWidget {
  const ReadingHeroBlock({
    super.key,
    required this.card,
    required this.isRead,
    required this.onTap,
  });

  final DayCard card;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            // Заливка, а не контур: герой должен читаться как отдельный
            // объект, а не как ещё одна рамка в ряду рамок.
            color: colors.accent.withValues(alpha: isDark ? 0.20 : 0.13),
            border: Border.all(
              color: colors.accent.withValues(alpha: isDark ? 0.42 : 0.34),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_stories_outlined,
                      size: 17, color: colors.accent),
                  const SizedBox(width: 8),
                  Text(
                    'ЧТЕНИЕ ДНЯ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.9,
                      color: colors.accent,
                    ),
                  ),
                  const Spacer(),
                  if (isRead)
                    Icon(Icons.check_circle, size: 17, color: colors.accent),
                ],
              ),
              const SizedBox(height: 16),
              // Ссылка отрывка антиквой и крупно — это и есть «что именно
              // я сегодня читаю», а не служебная подпись.
              Text(
                card.body,
                style: AppTheme.quoteStyle(context)
                    .copyWith(fontSize: 30, height: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                'Евангелие по одному стиху за раз,\nс толкованием к каждому',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
