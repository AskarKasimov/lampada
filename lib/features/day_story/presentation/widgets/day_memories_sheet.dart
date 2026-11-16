import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../daily_cards/domain/entities/day_memory.dart';

/// Все поминаемые в день святые, праздники и иконы, у которых есть рассказ,
/// в порядке Азбуки. Возвращает выбранную память или null, если шторку
/// закрыли.
Future<DayMemory?> showDayMemoriesSheet(
  BuildContext context, {
  required List<DayMemory> memories,
  required String currentUrl,
  required Set<String> readUrls,
}) => showModalBottomSheet<DayMemory>(
  context: context,
  // Как оглавление курса: без корневого навигатора низ шторки ушёл бы под
  // капсулу навбара.
  useRootNavigator: true,
  sheetAnimationStyle: const AnimationStyle(
    duration: AppMotion.modalEnter,
    reverseDuration: AppMotion.modalExit,
  ),
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: AppColorsExtension.of(context).background,
  builder: (_) => DayMemoriesSheet(
    memories: memories,
    currentUrl: currentUrl,
    readUrls: readUrls,
  ),
);

class DayMemoriesSheet extends StatelessWidget {
  const DayMemoriesSheet({
    required this.memories,
    required this.currentUrl,
    required this.readUrls,
    super.key,
  });

  final List<DayMemory> memories;

  /// Рассказ, открытый сейчас.
  final String currentUrl;
  final Set<String> readUrls;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final padding = AppSpacing.of(context).horizontal;
    final read = memories.where((m) => readUrls.contains(m.storyUrl)).length;
    // Святых в дне обычно несколько, поэтому шторка по содержимому, а не на
    // весь экран, как оглавление курса.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: padding + const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Память дня', style: AppTheme.cardTitleStyle(context)),
                const SizedBox(height: 3),
                Text(
                  'Прочитано $read из ${memories.length}',
                  style: AppTheme.cardCaptionStyle(context),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 12,
              ),
              itemCount: memories.length,
              itemBuilder: (context, index) {
                final memory = memories[index];
                final isCurrent = memory.storyUrl == currentUrl;
                final isRead = readUrls.contains(memory.storyUrl);
                return Semantics(
                  button: true,
                  excludeSemantics: true,
                  label: [
                    memory.title,
                    if (isCurrent) 'Сейчас',
                    if (isRead) 'Прочитано',
                  ].join('. '),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(memory),
                    child: Container(
                      // Подсветка того же тона, что плашка в шапке рассказа.
                      color: isCurrent
                          ? colors.ink.withValues(alpha: 0.06)
                          : null,
                      padding:
                          padding + const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              memory.title,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.25,
                                fontWeight: isCurrent
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: colors.ink,
                              ),
                            ),
                          ),
                          if (isRead)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Icon(
                                CupertinoIcons.checkmark_alt,
                                size: 18,
                                color: colors.accent,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
