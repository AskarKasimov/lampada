import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../domain/course_calendar.dart';
import '../../domain/entities/day_card.dart';
import 'day_entry_row.dart';
import 'home_tile.dart';
import 'read_status_checks.dart';

/// Вход в личный курс на вкладке «Главная»: заголовок и счётчик тем под ним.
/// Тема звучит только для скринридера; справка о курсе открывается из
/// читалки.
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
    final topicNumber = _topicNumber;
    final count = completedTopicCount;
    final progressLabel = count == null
        ? 'Тема $topicNumber из $courseTopicCount'
        : 'Прочитано $count из $courseTopicCount';
    final title = count == courseTopicCount
        ? 'Курс пройден'
        : topic.title ?? 'Тема $topicNumber';
    return HomeTile(
      title: basicsCourseTitle,
      type: CardType.basics,
      illustration: (color) => Icon(
        CupertinoIcons.book,
        size: HomeTile.illustrationSize,
        color: color,
      ),
      semanticsLabel: '$basicsCourseTitle. $progressLabel. $title',
      onTap: onTap,
      titleTrailing: ReadStatusChecks(isUnread: isUnread),
      subtitle: count == null ? null : '$count/$courseTopicCount',
    );
  }
}
