import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/course_calendar.dart';
import '../../domain/entities/day_card.dart';
import '../theme/card_type_style.dart';
import 'day_entry_row.dart';

/// Постоянный вход в личный курс над календарными страницами.
///
/// Курс не зависит от выбранной даты, поэтому его прогресс не должен уезжать
/// вместе с содержимым дня при листании календаря.
class CourseProgressHeader extends StatelessWidget {
  const CourseProgressHeader({
    required this.topic,
    required this.onTap,
    super.key,
  });

  final DayCard topic;
  final VoidCallback onTap;

  int get _topicNumber {
    final match = RegExp(r'^basics-topic-(\d+)$').firstMatch(topic.id);
    return int.tryParse(match?.group(1) ?? '') ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final brightness = Theme.of(context).brightness;
    final topicNumber = _topicNumber;
    final title = topic.title ?? 'Тема $topicNumber';
    final courseAccent = CardType.basics.styleFor(brightness).accent;

    return Semantics(
      button: true,
      label:
          '$basicsCourseTitle. Тема $topicNumber из $courseTopicCount. '
          '$title',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.chipUnreadBorder),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                      'Тема $topicNumber из $courseTopicCount',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 18, color: colors.homeIcon),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.3,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(1),
                  child: LinearProgressIndicator(
                    value: topicNumber / courseTopicCount,
                    minHeight: 2,
                    color: courseAccent,
                    backgroundColor: colors.chipUnreadBorder,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
