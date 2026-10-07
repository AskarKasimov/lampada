import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/course_calendar.dart';
import '../providers/providers.dart';
import '../widgets/day_entry_row.dart';

/// Описание личного курса, доступное из читалки.
class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColorsExtension.of(context);
    final topic = ref.watch(courseTopicProvider);
    final completed = ref.watch(completedCourseTopicsProvider);
    final count = completed.value?.length;
    final currentTopic = topic.value;
    final isFinished = count == courseTopicCount;
    final bodyStyle = TextStyle(fontSize: 17, height: 1.5, color: colors.ink);

    return Scaffold(
      appBar: AppBar(
        title: const Text(basicsCourseTitle),
        backgroundColor: colors.background,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding:
              AppSpacing.of(context).horizontal +
              const EdgeInsets.only(top: 24, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'О курсе',
                style: bodyStyle.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '365 тем об основах православной веры и жизни христианина. '
                'Читайте по одной теме в день или двигайтесь в своём темпе.',
                style: bodyStyle,
              ),
              const SizedBox(height: 16),
              Text('Источник: «Азбука веры»', style: bodyStyle),
              const SizedBox(height: 32),
              Text(
                'Ваш прогресс',
                style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (count != null) ...[
                Text(
                  isFinished
                      ? 'Курс пройден'
                      : 'Прочитано $count из $courseTopicCount',
                  style: bodyStyle,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: count / courseTopicCount),
              ] else if (completed.isLoading)
                const Text('Загружаем прогресс…')
              else
                TextButton(
                  onPressed: () =>
                      ref.invalidate(completedCourseTopicsProvider),
                  child: const Text('Повторить загрузку прогресса'),
                ),
              const SizedBox(height: 20),
              if (currentTopic != null)
                Text(
                  '${isFinished ? 'Для повторного чтения' : 'Текущее чтение'}: '
                  '${currentTopic.title ?? basicsCourseTitle}',
                  style: bodyStyle,
                )
              else if (topic.isLoading)
                const Text('Загружаем тему…')
              else
                TextButton(
                  onPressed: () => ref.invalidate(courseTopicProvider),
                  child: const Text('Повторить загрузку темы'),
                ),
              const SizedBox(height: 32),
              Text(
                'Листайте текст темы короткими фрагментами. Дочитав последний, '
                'свайпните дальше: откроется следующая тема, а прочитанная '
                'сохранится в прогрессе. Авторы советуют читать по одной теме '
                'в день. При возвращении откроется последняя просмотренная '
                'карточка.',
                style: bodyStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
