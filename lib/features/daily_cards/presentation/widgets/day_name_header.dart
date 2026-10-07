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
          const EdgeInsets.only(top: 4, bottom: 16),
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
          if ((day.title ?? '').isNotEmpty) _title(context, canOpen),
        ],
      ),
    );
    return canOpen ? InkWell(onTap: onTap, child: content) : content;
  }

  Widget _title(BuildContext context, bool canOpen) {
    final style = AppTheme.quoteStyle(
      context,
    ).copyWith(fontSize: 25, height: 1.22);
    final title = day.title!.trimRight();
    if (!canOpen) return Text(title, style: style);
    // Последнее слово и стрелка собраны в один неразрывный блок: иначе на
    // некоторых ширинах стрелка висит одна на новой строке. Символ
    // запрета переноса (U+2060) перед WidgetSpan во Flutter не действует.
    final split = title.lastIndexOf(' ') + 1;
    return Text.rich(
      TextSpan(
        text: title.substring(0, split),
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(title.substring(split), style: style)),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    CupertinoIcons.chevron_right,
                    size: 22,
                    color: AppColorsExtension.of(context).homeSubtitle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      style: style,
    );
  }
}
