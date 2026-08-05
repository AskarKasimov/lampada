import 'package:flutter/material.dart';

import '../../../../core/format/russian_date.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/bookmark.dart';

/// Запись копилки. Текст — главный вес (§6), дата и источник приглушены.
class BookmarkTile extends StatelessWidget {
  const BookmarkTile({
    required this.bookmark,
    required this.onRemove,
    super.key,
  });

  final Bookmark bookmark;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Dismissible(
      key: ValueKey(bookmark.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        child: Icon(Icons.delete_outline, color: colors.textSecondary),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bookmark.text,
              style: AppTheme.quoteStyle(
                context,
              ).copyWith(fontSize: 17, height: 1.5),
            ),
            const SizedBox(height: 10),
            Text(
              '${bookmark.label} · ${bookmark.source} · '
              '${russianDayMonth(bookmark.savedAt)}',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
