import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/bookmark.dart';
import '../providers/providers.dart';

/// Кнопка «в копилку» на карточке, стихе и толковании.
///
/// Тихая иконка, а не подписанная кнопка: §6 отдаёт высокий контраст только
/// самому контенту и «Дальше». Подтверждение — снекбар «Сохранено в копилку»
/// (FR-016), потому что смена иконки на 20 пикселей легко проходит мимо глаз.
class BookmarkButton extends ConsumerWidget {
  const BookmarkButton({required this.bookmark, super.key});

  /// Готовая запись: вызывающий знает и текст, и происхождение.
  /// savedAt проставляется в момент нажатия, поэтому здесь он не важен.
  final Bookmark bookmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(
      bookmarksProvider.select(
        (state) =>
            (state.value ?? const <Bookmark>[]).any((b) => b.id == bookmark.id),
      ),
    );
    final colors = AppColorsExtension.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    return IconButton(
      tooltip: saved ? 'Убрать из копилки' : 'Сохранить в копилку',
      visualDensity: VisualDensity.compact,
      onPressed: () async {
        final changed = await ref
            .read(bookmarksProvider.notifier)
            .toggle(bookmark.copyWith(savedAt: DateTime.now()));
        if (!changed) {
          messenger?.showSnackBar(
            const SnackBar(
              content: Text('Не удалось сохранить закладку'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        if (saved) return;
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Сохранено в копилку'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      icon: Icon(
        saved ? Icons.bookmark : Icons.bookmark_border,
        size: 20,
        color: saved ? colors.accent : colors.homeSubtitle,
      ),
    );
  }
}
