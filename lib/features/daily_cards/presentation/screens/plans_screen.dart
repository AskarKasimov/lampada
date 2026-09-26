import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_loading_view.dart';
import '../../../reminders/presentation/providers/providers.dart';
import '../../../reminders/presentation/screens/reminder_permission_screen.dart';
import '../../../shell/presentation/widgets/floating_nav_bar.dart';
import '../../domain/entities/day_card.dart';
import '../providers/providers.dart';
import '../widgets/course_progress_header.dart';
import 'course_reader_screen.dart';
import 'plans_info_screen.dart';

/// Личные курсы не зависят от выбранной даты на «Домой».
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColorsExtension.of(context);
    final topic = ref.watch(courseTopicProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          titleSpacing: 20,
          backgroundColor: colors.background,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text('Планы', style: TextStyle(color: colors.ink)),
          actions: [
            IconButton(
              tooltip: 'Помощь',
              color: colors.textSecondary,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PlansInfoScreen(),
                ),
              ),
              icon: const Icon(CupertinoIcons.info),
            ),
          ],
        ),
        if (topic.value case final currentTopic?)
          SliverToBoxAdapter(
            child: CourseProgressHeader(
              topic: currentTopic,
              onTap: () => _openCourse(context, ref, currentTopic),
            ),
          )
        else if (topic.isLoading)
          const SliverFillRemaining(child: BrandLoadingView())
        else
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, kFloatingNavInset),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Не удалось загрузить «Основы веры»'),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => ref.invalidate(courseTopicProvider),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: kFloatingNavInset)),
      ],
    );
  }

  Future<void> _openCourse(
    BuildContext context,
    WidgetRef ref,
    DayCard topic,
  ) async {
    final currentTopic = await ref.read(courseTopicProvider.future) ?? topic;
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
}
