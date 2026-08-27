import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/format/russian_date.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/bookmark.dart';
import '../screens/bookmark_detail_screen.dart';

/// Запись копилки в списке — превью в несколько строк, а не весь текст.
///
/// Раньше сюда шёл текст целиком без ограничения: толкование на несколько
/// абзацев или длинный совет дня растягивали список так, что смотреть его
/// было невозможно — один сохранённый текст занимал экран целиком. Полный
/// текст теперь открывается тапом, тем же полноэкранным приёмом, что
/// карточки дня на «Сегодня» (см. [BookmarkDetailScreen]).
class BookmarkTile extends StatelessWidget {
  const BookmarkTile({
    required this.bookmark,
    required this.onRemove,
    super.key,
  });

  final Bookmark bookmark;
  final Future<bool> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Dismissible(
      key: ValueKey(bookmark.id),
      direction: DismissDirection.endToStart,
      // Не убираем плитку до подтверждённой записи: иначе свайп создаёт
      // впечатление удаления, хотя prefs мог отклонить операцию.
      confirmDismiss: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        child: Icon(CupertinoIcons.trash, color: colors.textSecondary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (_) => BookmarkDetailScreen(bookmark: bookmark),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bookmark.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.quoteStyle(
                    context,
                  ).copyWith(fontSize: 17, height: 1.5),
                ),
                const SizedBox(height: 10),
                Text(
                  '${bookmark.label} · ${bookmark.source} · '
                  '${russianDayMonth(bookmark.savedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
