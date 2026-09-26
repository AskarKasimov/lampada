import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/today_cards.dart';

/// Память дня и пост; открывает рассказ, когда есть [TodayCards.storyUrl].
class DayNameHeader extends StatelessWidget {
  const DayNameHeader({required this.day, super.key, this.onTap});

  final TodayCards day;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final canOpen =
        onTap != null && day.storyUrl != null && (day.title ?? '').isNotEmpty;
    final content = Padding(
      // Пометка поста и воздух до разделителя входят в одну область ink.
      padding:
          AppSpacing.of(context).horizontal +
          const EdgeInsets.only(top: 4, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Text.rich(
              TextSpan(
                text: day.title!,
                children: [
                  if (canOpen)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(
                          CupertinoIcons.chevron_right,
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
        ],
      ),
    );
    return canOpen ? InkWell(onTap: onTap, child: content) : content;
  }
}
