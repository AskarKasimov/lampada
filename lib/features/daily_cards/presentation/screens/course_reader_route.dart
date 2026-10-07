import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';

import '../../../reminders/presentation/providers/providers.dart';
import '../../../reminders/presentation/screens/reminder_permission_screen.dart';
import '../../domain/entities/day_card.dart';
import '../providers/providers.dart';
import 'course_reader_screen.dart';

/// Вход в читалку из списка планов.
Future<void> openCourseReader(BuildContext context, WidgetRef ref) async {
  DayCard? currentTopic;
  try {
    currentTopic = await ref.read(courseTopicProvider.future);
  } on Object {
    currentTopic = null;
  }
  if (!context.mounted) return;
  if (currentTopic == null) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Не удалось загрузить место чтения')),
    );
    return;
  }
  final number =
      int.tryParse(currentTopic.id.replaceFirst('basics-topic-', '')) ?? 1;
  final pageResult = await ref.read(getCoursePageProvider)(number);
  if (!context.mounted) return;
  if (pageResult case Failure()) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Не удалось загрузить место чтения')),
    );
    return;
  }
  final page = (pageResult as Success<int?>).value ?? 0;
  // Только явный вход в читалку создаёт активный план и первую позицию.
  final started = await ref.read(saveCourseTopicProvider)(number, page: page);
  if (!context.mounted) return;
  if (started case Failure()) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Не удалось сохранить место чтения')),
    );
    return;
  }
  ref.invalidate(hasStartedCourseProvider);
  // Открывается внутри вкладки, а не модально: навбар остаётся виден.
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          CourseReaderScreen(currentTopic: currentTopic!, initialPage: page),
    ),
  );
  if (!context.mounted) return;

  final read = ref.read(dayProgressProvider).value?.readTypes ?? const {};
  if (read.isEmpty) return;
  final settings = await ref.read(reminderSettingsProvider.future);
  if (settings.asked || !context.mounted) return;
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const ReminderPermissionScreen(),
    ),
  );
}
