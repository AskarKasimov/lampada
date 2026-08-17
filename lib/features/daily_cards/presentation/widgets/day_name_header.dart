import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/today_cards.dart';

/// Память дня и пометка поста.
///
/// До неё «Сегодня» показывало только число в сетке — приложение про
/// церковный календарь не говорило, какой сегодня день. Имя набрано антиквой:
/// это заголовок страницы, а не служебная подпись.
///
/// Седмицы здесь нет намеренно: она свойство недели, а не дня, и живёт над
/// полоской. Рядом с памятью она читалась как часть титула святого.
///
/// Заголовок кликабелен, когда за ним стоит рассказ ([TodayCards.storyUrl]
/// не пуст): без стрелки в конце строки это читалось бы просто подписью,
/// а не входом в праздник — как совет или притча, у которых своя карточка.
class DayNameHeader extends StatelessWidget {
  const DayNameHeader({required this.day, super.key, this.onTap});

  final TodayCards day;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final canOpen = onTap != null && day.storyUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (day.isFast) ...[
          Text(
            'ПОСТНЫЙ ДЕНЬ',
            style: TextStyle(
              fontSize: 10,
              height: 1.4,
              letterSpacing: 1.1,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if ((day.title ?? '').isNotEmpty)
          if (canOpen)
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Text.rich(
                TextSpan(
                  text: day.title!,
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.chevron_right,
                          size: 22,
                          color: colors.homeSubtitle,
                        ),
                      ),
                    ),
                  ],
                ),
                style: AppTheme.quoteStyle(
                  context,
                ).copyWith(fontSize: 25, height: 1.22),
              ),
            )
          else
            Text(
              day.title!,
              style: AppTheme.quoteStyle(
                context,
              ).copyWith(fontSize: 25, height: 1.22),
            ),
      ],
    );
  }
}
