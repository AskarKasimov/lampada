import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bookmarks/presentation/screens/bookmarks_screen.dart';
import '../../../daily_cards/domain/entities/day_card.dart';
import '../../../daily_cards/presentation/providers/providers.dart';
import '../../../daily_cards/presentation/screens/course_reader_screen.dart';
import '../../../daily_cards/presentation/screens/today_screen.dart';
import '../../../daily_cards/presentation/widgets/course_progress_header.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../reminders/presentation/providers/providers.dart';
import '../../../reminders/presentation/screens/reminder_permission_screen.dart';
import '../../../reminders/presentation/widgets/reminder_scheduler.dart';
import '../providers/shell_providers.dart';
import '../widgets/floating_nav_bar.dart';

/// Дом приложения: три вкладки. Экрана-прослойки между запуском и контентом
/// нет — корень «Сегодня» это сам день, чтобы первая мысль встречала юзера
/// сразу, а не после тапа по дашборду.
///
/// [IndexedStack], а не пересборка: уход на другую вкладку и обратно не должен
/// сбрасывать состояние экрана.
///
/// Навигация лежит в [Stack] поверх контента, а не в `bottomNavigationBar`:
/// глухая полоса снизу отрезала у экрана заметный кусок. Контент уходит под
/// капсулу, поэтому скроллящиеся вкладки оставляют снизу [kFloatingNavInset].
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(selectedTabProvider);
    final courseTopic = tab == ShellTab.today
        ? ref.watch(courseTopicProvider).value
        : null;

    return ReminderScheduler(
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: tab.index,
                children: const [
                  TodayScreen(),
                  BookmarksScreen(),
                  ProfileScreen(),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingNavBar(
                current: tab,
                onSelect: (selected) =>
                    ref.read(selectedTabProvider.notifier).select(selected),
                header: courseTopic == null
                    ? null
                    : CourseProgressHeader(
                        topic: courseTopic,
                        compact: true,
                        onTap: () => _openCourse(context, ref, courseTopic),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openCourse(
  BuildContext context,
  WidgetRef ref,
  DayCard courseTopic,
) async {
  final currentTopic =
      await ref.read(courseTopicProvider.future) ?? courseTopic;
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => CourseReaderScreen(currentTopic: currentTopic),
    ),
  );
  if (!context.mounted) return;

  final read = ref.read(dayProgressProvider).value?.readTypes ?? const {};
  if (read.isEmpty) return;
  final settings = await ref.read(reminderSettingsProvider.future);
  if (settings.asked || !context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const ReminderPermissionScreen(),
    ),
  );
}
