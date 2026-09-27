import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/brand_loading_view.dart';
import '../../../shell/presentation/widgets/floating_nav_bar.dart';
import '../providers/providers.dart';
import '../widgets/course_progress_header.dart';
import 'course_detail_screen.dart';
import 'plans_info_screen.dart';

/// Личные курсы не зависят от выбранной даты на «Домой».
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColorsExtension.of(context);
    final navInset = FloatingNavInset.of(context);
    final topic = ref.watch(courseTopicProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
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
              completedTopicCount: ref
                  .watch(completedCourseTopicsProvider)
                  .value
                  ?.length,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CourseDetailScreen(),
                ),
              ),
            ),
          )
        else if (topic.isLoading)
          const SliverFillRemaining(child: BrandLoadingView())
        else
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding:
                  AppSpacing.of(context).horizontal +
                  EdgeInsets.only(top: 20, bottom: navInset),
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
        SliverToBoxAdapter(child: SizedBox(height: navInset)),
      ],
    );
  }
}
