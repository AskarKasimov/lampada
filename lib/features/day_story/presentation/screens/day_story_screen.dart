import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_link_button.dart';
import '../../../../core/widgets/app_share_button.dart';
import '../../../../core/widgets/brand_loading_view.dart';
import '../../../../core/widgets/selectable_share_area.dart';
import '../../../bookmarks/domain/entities/bookmark.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../domain/entities/day_story.dart';
import '../providers/providers.dart';

/// Рассказ о празднике или святом дня — открывается тапом по заголовку
/// на «Сегодня».
///
/// Текст выключен по левому краю, а не центрирован, как цитата: рассказ
/// бывает на несколько экранов (у больших праздников — с историческим
/// разбором на тысячи слов), и простыня по центру на таком объёме
/// нечитаема (тот же принцип, что у толкования).
class DayStoryScreen extends ConsumerWidget {
  const DayStoryScreen({
    required this.title,
    required this.storyUrl,
    super.key,
  });

  final String title;
  final String storyUrl;

  /// savedAt — заглушка, момент сохранения ставит сама кнопка.
  Bookmark _bookmarkFor(DayStory story) => Bookmark(
    id: 'story-$storyUrl',
    kind: BookmarkKind.story,
    text: story.paragraphs.join('\n\n'),
    source: title,
    label: 'Память дня',
    savedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  String _shareTextFor(DayStory story) =>
      '$title\n\n${story.paragraphs.join('\n\n')}\n\n— Азбука веры';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dayStoryProvider(storyUrl));
    final colors = AppColorsExtension.of(context);

    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const BrandLoadingView(),
          error: (e, _) => _ErrorView(
            kind: switch (e) {
              AppFailure(kind: final k) => k,
              _ => FailureKind.unknown,
            },
            onRetry: () => ref.invalidate(dayStoryProvider(storyUrl)),
            onClose: () => Navigator.of(context).pop(),
          ),
          data: (story) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    const Spacer(),
                    BookmarkButton(bookmark: _bookmarkFor(story)),
                    AppShareButton(text: _shareTextFor(story)),
                    AppLinkButton(
                      label: 'Закрыть',
                      color: colors.homeSubtitle,
                      fontSize: 12,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _StoryView(title: title, story: story),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryView extends StatelessWidget {
  const _StoryView({required this.title, required this.story});

  final String title;
  final DayStory story;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final content = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.quoteStyle(
              context,
            ).copyWith(fontSize: 25, height: 1.25),
          ),
          const SizedBox(height: 20),
          for (final paragraph in story.paragraphs) ...[
            Text(
              paragraph,
              style: TextStyle(fontSize: 16, height: 1.65, color: colors.ink),
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 8),
          Text(
            '— Азбука веры',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 0.2,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
    return SelectableShareArea(child: content);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.kind,
    required this.onRetry,
    required this.onClose,
  });

  final FailureKind kind;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    // unknown здесь покрывает и «страница другого шаблона»: у некоторых
    // праздников ссылка ведёт не на карточку дня, а на отдельную статью
    // без рассказа (см. Пасху) — такое чинится не повтором запроса.
    final title = kind == FailureKind.network
        ? 'Нет подключения к интернету'
        : 'Рассказ сейчас недоступен';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.ink),
            ),
            const SizedBox(height: 6),
            Text(
              'Карточки дня остаются с вами',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.homeSubtitle),
            ),
            const SizedBox(height: 12),
            AppLinkButton(
              label: 'Повторить',
              color: colors.link,
              fontSize: 12,
              onPressed: onRetry,
            ),
            AppLinkButton(
              label: 'Закрыть',
              color: colors.homeSubtitle,
              fontSize: 12,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
