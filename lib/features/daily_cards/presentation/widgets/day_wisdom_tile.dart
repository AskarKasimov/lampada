import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'read_status_checks.dart';

/// Крупный вход в дневные материалы с отметкой их общего прочтения.
class DayWisdomTile extends StatelessWidget {
  const DayWisdomTile({
    required this.isUnread,
    required this.onTap,
    this.isLoading = false,
    super.key,
  });

  final bool isUnread;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Semantics(
      button: true,
      enabled: !isLoading,
      value: isLoading ? 'Загружаем материалы дня' : null,
      label: 'Мудрость дня${isUnread ? '' : '. Прочитано'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          child: Padding(
            padding:
                AppSpacing.of(context).horizontal +
                const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accent.withValues(alpha: 0.12),
                  ),
                  child: isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.accent,
                          ),
                        )
                      : Icon(
                          CupertinoIcons.calendar,
                          size: 28,
                          color: colors.accent,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Мудрость дня',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ReadStatusChecks(isUnread: isUnread),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Цитата, совет, притча и Евангелие',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: colors.homeSubtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: colors.homeSubtitle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
