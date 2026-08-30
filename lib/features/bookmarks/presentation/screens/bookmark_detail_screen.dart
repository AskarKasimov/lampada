import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/format/russian_date.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_pill_badge.dart';
import '../../domain/entities/bookmark.dart';
import '../widgets/bookmark_button.dart';

/// Скорость свайпа вниз (лог.px/с), после которой экран закрывается —
/// то же значение, что у просмотрщика карточек дня.
const _dismissVelocity = 700.0;

/// Полный текст сохранённой записи.
///
/// Список копилки показывает только начало (см. [BookmarkTile]) — весь текст
/// живёт здесь, тем же полноэкранным приёмом, что карточки дня: одна мысль
/// на экран, закрывается крестиком или свайпом вниз.
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

    return Scaffold(
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
                    const SizedBox(height: 48),
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
              // Тот же жест, что на карточках дня: крестик и свайп вниз —
              // обе привычные для iOS пары для модального экрана.
              Positioned(
                top: 0,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    CupertinoIcons.xmark,
                    size: 22,
                    color: colors.homeSubtitle,
                  ),
                  tooltip: 'Закрыть',
                ),
              ),
              // Та же кнопка, что на карточке дня, стихе и толковании — сюда
              // попадают уже сохранённые записи, поэтому она стоит заполненной
              // и повторный тап снимает закладку: экран остаётся открытым,
              // текст никуда не пропадает, просто выходит из копилки.
              Positioned(
                top: 0,
                left: 8,
                child: BookmarkButton(bookmark: bookmark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
