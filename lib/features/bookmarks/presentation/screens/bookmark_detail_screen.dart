import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/format/russian_date.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_pill_badge.dart';
import '../../../../core/widgets/app_share_button.dart';
import '../../../../core/widgets/fullscreen_swipe_dismiss.dart';
import '../../../bible/presentation/navigation/open_bible_viewer.dart';
import '../../../daily_cards/domain/entities/day_card.dart';
import '../../../daily_cards/presentation/theme/card_type_style.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/usecases/resolve_bookmark_chapter.dart';
import '../widgets/bookmark_button.dart';

/// Полный текст сохранённой записи.
///
/// Список копилки показывает только начало (см. [BookmarkTile]) — весь текст
/// живёт здесь, тем же полноэкранным приёмом, что карточки дня: одна мысль
/// на экран, возвращается к списку крестиком или горизонтальным свайпом.
class BookmarkDetailScreen extends StatelessWidget {
  const BookmarkDetailScreen({required this.bookmark, super.key});

  final Bookmark bookmark;

  /// Короткие цитаты держат крупный шрифт, длинные толкования и советы —
  /// мельче, чтобы меньше скроллить. Тот же порог, что у карточек дня.
  static double _fontSizeFor(int length) {
    if (length <= 220) return 24;
    if (length <= 500) return 21;
    return 18;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final chapter = const ResolveBookmarkChapter()(bookmark);
    final actionCount = chapter == null ? 2 : 3;
    final actionColumnHeight = actionCount * 56.0 + (actionCount - 1) * 4.0;
    final brightness = Theme.of(context).brightness;
    final type = switch (bookmark.kind) {
      BookmarkKind.verse || BookmarkKind.interpretation => CardType.reading,
      BookmarkKind.story => CardType.quote,
      BookmarkKind.card => CardType.values.firstWhere(
        (type) => type.styleFor(brightness).label == bookmark.label,
        orElse: () => CardType.quote,
      ),
    };
    final style = type.styleFor(brightness);

    return FullscreenSwipeDismiss(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.background,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: AppPillBadge(
            label: bookmark.label,
            background: style.tagBackground,
            foreground: style.tagForeground,
            letterSpacing: 0.2,
          ),
          actions: [
            IconButton(
              tooltip: 'Закрыть закладку',
              onPressed: () => Navigator.of(context).pop(),
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              padding: EdgeInsets.zero,
              icon: Icon(
                CupertinoIcons.xmark,
                size: 22,
                color: colors.homeSubtitle,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: AppSpacing.of(context).horizontal,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                bookmark.text,
                                textAlign: TextAlign.center,
                                style: AppTheme.quoteStyle(context).copyWith(
                                  fontSize: _fontSizeFor(bookmark.text.length),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '— ${bookmark.source}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  letterSpacing: 0.2,
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                russianDayMonth(bookmark.savedAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: actionColumnHeight + 28 + 16),
                  ],
                ),
              ),
              Positioned(
                right: 12,
                bottom: 28,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (chapter != null) ...[
                      IconButton(
                        tooltip: 'Открыть главу',
                        onPressed: () => openBibleViewer(
                          context,
                          book: chapter.book,
                          chapter: chapter.chapter,
                          verse: chapter.verse,
                          source: BibleOpenSource.bookmark,
                        ),
                        constraints: const BoxConstraints.tightFor(
                          width: 56,
                          height: 56,
                        ),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          CupertinoIcons.book,
                          size: 28,
                          color: colors.homeSubtitle,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    BookmarkButton(
                      bookmark: bookmark,
                      placement: BookmarkPlacement.detail,
                      iconSize: 28,
                      buttonSize: 56,
                    ),
                    AppShareButton(
                      text: '${bookmark.text}\n\n— ${bookmark.source}',
                      content: SharedContent.bookmark,
                      iconSize: 28,
                      buttonSize: 56,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
