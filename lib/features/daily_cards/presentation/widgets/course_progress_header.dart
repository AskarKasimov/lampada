import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/course_calendar.dart';
import '../../domain/entities/day_card.dart';
import '../theme/card_type_style.dart';
import 'day_entry_row.dart';
import 'read_status_checks.dart';

/// Вход в личный курс с текущей темой и прогрессом на «Домой».
class CourseProgressHeader extends StatelessWidget {
  const CourseProgressHeader({
    required this.topic,
    required this.onTap,
    required this.completedTopicCount,
    this.isUnread = true,
    super.key,
  });

  final DayCard topic;
  final VoidCallback onTap;
  final bool isUnread;
  final int? completedTopicCount;

  int get _topicNumber {
    final match = RegExp(r'^basics-topic-(\d+)$').firstMatch(topic.id);
    return int.tryParse(match?.group(1) ?? '') ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final brightness = Theme.of(context).brightness;
    final topicNumber = _topicNumber;
    final count = completedTopicCount;
    final progressLabel = count == null
        ? 'Тема $topicNumber из $courseTopicCount'
        : 'Прочитано $count из $courseTopicCount';
    final title = count == courseTopicCount
        ? 'Курс пройден'
        : topic.title ?? 'Тема $topicNumber';
    final courseAccent = CardType.basics.styleFor(brightness).accent;

    return Semantics(
      button: true,
      label:
          '$basicsCourseTitle. Тема $topicNumber из $courseTopicCount. '
          '$progressLabel. $title',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            margin:
                AppSpacing.of(context).horizontal +
                const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ReadStatusChecks(isUnread: isUnread),
                    Expanded(
                      child: Text(
                        basicsCourseTitle.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.4,
                          letterSpacing: 1.1,
                          color: courseAccent,
                        ),
                      ),
                    ),
                    Text(
                      progressLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 18,
                      color: colors.homeIcon,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          height: 1.3,
                          color: colors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                if (count != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(1),
                    child: LinearProgressIndicator(
                      value: count / courseTopicCount,
                      minHeight: 2,
                      color: courseAccent,
                      backgroundColor: colors.chipUnreadBorder,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
