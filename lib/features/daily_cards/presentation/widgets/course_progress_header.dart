import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/course_calendar.dart';
import '../../domain/entities/day_card.dart';
import 'day_entry_row.dart';
import 'home_grid_tile.dart';
import 'read_status_checks.dart';

/// Вход в личный курс на вкладке «Главная». Той же анатомии, что плитки
/// «Памяти дня» и «Мудрости дня»: картина во всю плитку и матовое стекло
/// снизу, только плитка широкая. В стекле название, счётчик тем и
/// отметка прочтения. Тема звучит только для скринридера; справка о курсе
/// открывается из читалки.
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

  /// «Видение отроку Варфоломею» М. В. Нестерова (1889–1890), общественное
  /// достояние. Отрок получает дар понимания грамоты: сюжет о начале пути,
  /// как и курс. Обрезана заранее до широкого кадра с лицами и храмом.
  static const coverAsset = 'assets/illustrations/course_cover.jpg';

  /// Широкой плитке хватает меньшей высоты, чем квадратным плиткам дня.
  static const _height = 128.0;

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
    return Padding(
      padding:
          AppSpacing.of(context).horizontal +
          const EdgeInsets.symmetric(vertical: 6),
      child: HomeGridTile(
        title: basicsCourseTitle,
        type: CardType.basics,
        minimumHeight: _height,
        semanticsLabel: '$basicsCourseTitle. $progressLabel. $title',
        onTap: onTap,
        background: (_) => Image.asset(
          coverAsset,
          fit: BoxFit.cover,
          // Лица мальчика и старца в верхней части кадра, низ под стеклом.
          alignment: const Alignment(0, -0.4),
          excludeFromSemantics: true,
        ),
        titleTrailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count != null) ...[
              // На стекле поверх картины серая мелкая подпись терялась:
              // счётчик тёмный, как название, и крупнее подписи.
              Text(
                '$count/$courseTopicCount',
                style: AppTheme.cardCaptionStyle(context).copyWith(
                  fontSize: 16,
                  color: AppColorsExtension.of(context).ink,
                ),
              ),
              const SizedBox(width: 8),
            ],
            ReadStatusChecks(isUnread: isUnread),
          ],
        ),
      ),
    );
  }
}
