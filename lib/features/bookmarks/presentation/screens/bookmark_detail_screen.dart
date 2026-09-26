import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/format/russian_date.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_pill_badge.dart';
import '../../../bible/presentation/screens/bible_reader_screen.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/usecases/resolve_bookmark_chapter.dart';
import '../widgets/bookmark_button.dart';

/// Скорость свайпа вниз (лог.px/с), после которой экран закрывается —
/// то же значение, что у просмотрщика карточек дня.
const _dismissVelocity = 700.0;

/// Полный текст сохранённой записи.
///
/// Список копилки показывает только начало (см. [BookmarkTile]) — весь текст
/// живёт здесь, тем же полноэкранным приёмом, что карточки дня: одна мысль
/// на экран, возвращается к списку стрелкой назад или свайпом вниз.
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

  void _handleVerticalDrag(BuildContext context, DragEndDetails details) {
    if ((details.primaryVelocity ?? 0) >= _dismissVelocity) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final chapter = const ResolveBookmarkChapter()(bookmark);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.background,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
          color: colors.homeSubtitle,
        ),
        actions: [
          if (chapter != null)
            IconButton(
              tooltip: 'Открыть главу',
              icon: Icon(CupertinoIcons.book, color: colors.homeSubtitle),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BibleReaderScreen(
                    book: chapter.book,
                    chapter: chapter.chapter,
                    initialVerse: chapter.verse,
                  ),
                ),
              ),
            ),
          BookmarkButton(bookmark: bookmark),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragEnd: (details) => _handleVerticalDrag(context, details),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    AppPillBadge(
                      label: bookmark.label,
                      background: Colors.transparent,
                      foreground: colors.chipUnreadText,
                      border: Border.all(color: colors.chipUnreadBorder),
                      horizontalPadding: 13,
                      fontSize: 11.5,
                    ),
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
                    const SizedBox(height: 24),
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
