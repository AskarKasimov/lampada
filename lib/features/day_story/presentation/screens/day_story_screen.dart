import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_on_show.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_link_button.dart';
import '../../../../core/widgets/app_pill_badge.dart';
import '../../../../core/widgets/app_share_button.dart';
import '../../../../core/widgets/brand_loading_view.dart';
import '../../../../core/widgets/reading_action_space.dart';
import '../../../../core/widgets/reading_overflow_listener.dart';
import '../../../../core/widgets/selectable_share_area.dart';
import '../../../bookmarks/domain/entities/bookmark.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../../daily_cards/domain/entities/day_card.dart';
import '../../../daily_cards/domain/split_day_card_text.dart';
import '../../../daily_cards/presentation/screens/full_card_text_screen.dart';
import '../../../daily_cards/presentation/widgets/card_content.dart';
import '../../../daily_cards/presentation/widgets/reader_progress_rail.dart';
import '../../../daily_cards/presentation/widgets/vertical_card_reader.dart';
import '../../domain/entities/day_story.dart';
import '../providers/providers.dart';

/// Рассказ о празднике или святом дня — открывается тапом по заголовку
/// на «Сегодня».
///
/// Рассказ бывает на несколько экранов (у больших праздников с историческим
/// разбором на тысячи слов), поэтому он идёт листалкой по страницам, как
/// карточки дня, а не простынёй с прокруткой.
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
    // При закрытии ref этого виджета уже недоступен.
    final analytics = ref.read(analyticsProvider);

    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const BrandLoadingView(),
          error: (e, _) {
            final kind = switch (e) {
              AppFailure(kind: final k) => k,
              _ => FailureKind.unknown,
            };
            return AnalyticsOnShow(
              event: AnalyticsEvent.contentLoadFailed(
                content: LoadedContent.story,
                kind: kind.name,
              ),
              child: _StoryStatusView(
                kind: kind,
                onRetry: () {
                  analytics.log(
                    AnalyticsEvent.contentRetryTapped(LoadedContent.story),
                  );
                  ref.invalidate(dayStoryProvider(storyUrl));
                },
                onClose: () => Navigator.of(context).pop(),
              ),
            );
          },
          data: (story) => story.paragraphs.isEmpty
              ? _StoryStatusView(onClose: () => Navigator.of(context).pop())
              : _StoryReader(
                  title: title,
                  story: story,
                  bookmark: _bookmarkFor(story),
                  shareText: _shareTextFor(story),
                  onClose: () => Navigator.of(context).pop(),
                  onExit: (furthest, total, finished) => analytics.log(
                    AnalyticsEvent.storyClosed(
                      pagesSeen: furthest + 1,
                      pagesTotal: total,
                      finished: finished,
                    ),
                  ),
                  onFullText: () =>
                      analytics.log(AnalyticsEvent.fullTextOpened('story')),
                ),
        ),
      ),
    );
  }
}

/// Рассказ в той же вертикальной листалке, что «Мудрость дня»: обложка с
/// названием, затем текст страницами по несколько предложений. Длинный
/// рассказ большого праздника так читается без простыни и полноэкранного
/// режима, а полоса слева показывает, сколько осталось. Свайп дальше
/// последней страницы возвращает на главную.
class _StoryReader extends StatefulWidget {
  const _StoryReader({
    required this.title,
    required this.story,
    required this.bookmark,
    required this.shareText,
    required this.onClose,
    required this.onExit,
    required this.onFullText,
  });

  final String title;
  final DayStory story;
  final Bookmark bookmark;
  final String shareText;
  final VoidCallback onClose;

  /// Закрытие с самой дальней страницей и признаком «долистал до конца».
  final void Function(int furthest, int total, bool finished) onExit;
  final VoidCallback onFullText;

  @override
  State<_StoryReader> createState() => _StoryReaderState();
}

class _StoryReaderState extends State<_StoryReader> {
  final _controller = PageController();
  final _fullTextNeeded = <String, bool>{};
  var _index = 0;
  var _furthest = 0;

  late final List<DayCard> _pages = _pagesOf(widget.title, widget.story);

  /// Тип нужен карточке только для шрифта: рассказ набран, как притча дня.
  static List<DayCard> _pagesOf(String title, DayStory story) {
    final chunks = splitDayCardText(story.paragraphs.join('\n\n'));
    return [
      DayCard(
        id: 'story-title',
        type: CardType.parable,
        body: title,
        source: '',
      ),
      for (var i = 0; i < chunks.length; i++)
        DayCard(
          id: 'story-$i',
          type: CardType.parable,
          body: chunks[i],
          source: 'Азбука веры',
        ),
    ];
  }

  bool _isLast(int index) => index == _pages.length - 1;

  @override
  void dispose() {
    widget.onExit(_furthest, _pages.length, _closing);
    _controller.dispose();
    super.dispose();
  }

  /// За последней страницей идёт пустая служебная: долистав до неё, юзер
  /// закрывает рассказ тем же свайпом, каким читал.
  bool _isExit(int index) => index == _pages.length;

  var _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_closeAtExit);
  }

  /// Закрываем, только когда служебная страница встала на место: смена
  /// страницы засчитывается уже на середине свайпа, и рассказ закрывался бы
  /// под пальцем, который ещё может вернуться назад.
  void _closeAtExit() {
    if (_closing || !_controller.hasClients) return;
    if ((_controller.page ?? 0) < _pages.length - 0.001) return;
    _closing = true;
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final page = _pages[_index];
    return VerticalCardReader(
      controller: _controller,
      itemCount: _pages.length + 1,
      onPageChanged: (index) {
        if (!_isExit(index)) {
          setState(() {
            _index = index;
            if (index > _furthest) _furthest = index;
          });
        }
      },
      itemBuilder: (context, index) {
        if (_isExit(index)) return const SizedBox.shrink();
        final icon = widget.story.iconUrl;
        if (index == 0 && icon != null) {
          return SelectableShareArea(
            content: SharedContent.story,
            child: _StoryCover(title: widget.title, iconUrl: icon),
          );
        }
        final card = _pages[index];
        return ReadingOverflowListener(
          key: ValueKey(card.id),
          onChanged: (needed) {
            if (_fullTextNeeded[card.id] == needed) return;
            setState(() => _fullTextNeeded[card.id] = needed);
          },
          child: SelectableShareArea(
            content: SharedContent.story,
            child: CardContent(
              key: ValueKey(card.id),
              card: card,
              shareContent: SharedContent.story,
              showBadge: false,
              scrollable: false,
              // Источник подписывает весь рассказ, поэтому стоит в конце.
              showSource: index > 0 && _isLast(index),
            ),
          ),
        );
      },
      header: AppPillBadge(
        label: 'Память дня',
        background: colors.ink.withValues(alpha: 0.06),
        foreground: colors.textSecondary,
        letterSpacing: 0.2,
      ),
      leftRail: ReaderProgressRail(
        count: _pages.length,
        currentIndex: _index,
        accent: colors.accent,
      ),
      actions: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_fullTextNeeded[page.id] ?? false) ...[
            ReaderActionButton(
              tooltip: 'Открыть полный текст',
              onPressed: () {
                widget.onFullText();
                Navigator.of(context).push(
                  FullCardTextRoute(card: page, showSource: _isLast(_index)),
                );
              },
              icon: CupertinoIcons.fullscreen,
              color: colors.homeSubtitle,
            ),
            const SizedBox(height: 4),
          ],
          // Закладка и отправка относятся ко всему рассказу, а не к странице.
          BookmarkButton(
            bookmark: widget.bookmark,
            iconSize: 28,
            buttonSize: 56,
          ),
          const SizedBox(height: 4),
          AppShareButton(
            text: widget.shareText,
            content: SharedContent.story,
            iconSize: 28,
            buttonSize: 56,
          ),
        ],
      ),
      onClose: widget.onClose,
      closeColor: colors.homeSubtitle,
      topLeftAction: IconButton(
        tooltip: 'Закрыть рассказ',
        icon: Icon(CupertinoIcons.xmark, size: 22, color: colors.homeSubtitle),
        onPressed: widget.onClose,
      ),
    );
  }
}

/// Обложка рассказа: название наверху, под ним икона дня. Пока икона
/// грузится, на её месте спокойная подложка; если не загрузилась, остаётся
/// одно название.
class _StoryCover extends StatelessWidget {
  const _StoryCover({required this.title, required this.iconUrl});

  final String title;
  final String iconUrl;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Padding(
      // Низ оставляем кнопкам закладки и отправки, как у страниц текста.
      padding: EdgeInsets.only(bottom: ReadingActionSpace.of(context)),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.quoteStyle(
              context,
            ).copyWith(fontSize: 25, height: 1.25),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  iconUrl,
                  fit: BoxFit.contain,
                  semanticLabel: 'Икона: $title',
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : AspectRatio(
                          aspectRatio: 0.8,
                          child: ColoredBox(
                            color: colors.ink.withValues(alpha: 0.05),
                          ),
                        ),
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryStatusView extends StatelessWidget {
  const _StoryStatusView({required this.onClose, this.kind, this.onRetry});

  final FailureKind? kind;
  final VoidCallback? onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final title = switch (kind) {
      null => 'Нет описания сегодня',
      FailureKind.network => 'Нет подключения к интернету',
      _ => 'Рассказ сейчас недоступен',
    };

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: AppSpacing.of(context).horizontal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: colors.ink),
                ),
                if (kind != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Карточки дня остаются с вами',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: colors.homeSubtitle),
                  ),
                ],
                if (onRetry case final retry?) ...[
                  const SizedBox(height: 12),
                  AppLinkButton(
                    label: 'Повторить',
                    color: colors.link,
                    fontSize: 12,
                    onPressed: retry,
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: AppSpacing.of(context).horizontal.right,
          child: IconButton(
            tooltip: 'Закрыть рассказ',
            onPressed: onClose,
            icon: Icon(
              CupertinoIcons.xmark,
              size: 22,
              color: colors.homeSubtitle,
            ),
          ),
        ),
      ],
    );
  }
}
