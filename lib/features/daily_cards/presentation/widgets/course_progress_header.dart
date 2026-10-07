import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/course_calendar.dart';
import '../../domain/entities/day_card.dart';
import 'day_entry_row.dart';
import 'home_tile.dart';
import 'read_status_checks.dart';

/// Вход в личный курс на вкладке «Главная»: заголовок и полоса прогресса.
/// Тема и счётчик прочитанного звучат только для скринридера.
class CourseProgressHeader extends StatelessWidget {
  const CourseProgressHeader({
    required this.topic,
    required this.onTap,
    required this.completedTopicCount,
    this.isUnread = true,
    this.onInfo,
    super.key,
  });

  final DayCard topic;
  final VoidCallback onTap;
  final bool isUnread;
  final int? completedTopicCount;

  /// Открывает справку о курсе; без него кнопки нет.
  final VoidCallback? onInfo;

  int get _topicNumber {
    final match = RegExp(r'^basics-topic-(\d+)$').firstMatch(topic.id);
    return int.tryParse(match?.group(1) ?? '') ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final topicNumber = _topicNumber;
    final count = completedTopicCount;
    final progressLabel = count == null
        ? 'Тема $topicNumber из $courseTopicCount'
        : 'Прочитано $count из $courseTopicCount';
    final title = count == courseTopicCount
        ? 'Курс пройден'
        : topic.title ?? 'Тема $topicNumber';
    final onInfo = this.onInfo;

    return HomeTile(
      title: basicsCourseTitle,
      type: CardType.basics,
      illustration: (color) =>
          Icon(CupertinoIcons.book, size: 150, color: color),
      semanticsLabel: '$basicsCourseTitle. $progressLabel. $title',
      onTap: onTap,
      status: ReadStatusChecks(isUnread: isUnread),
      progress: count == null ? null : count / courseTopicCount,
      progressLabel: count == null ? null : '$count/$courseTopicCount',
      action: onInfo == null
          ? null
          : IconButton(
              tooltip: 'О курсе',
              color: AppColorsExtension.of(context).textSecondary,
              onPressed: onInfo,
              icon: const Icon(CupertinoIcons.info),
            ),
    );
  }
}
