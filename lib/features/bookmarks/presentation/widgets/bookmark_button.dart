import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/bookmark.dart';
import '../providers/providers.dart';

/// Кнопка «в копилку» на карточке, стихе и толковании.
///
/// Тихая иконка, а не подписанная кнопка: §6 отдаёт высокий контраст только
/// самому контенту и «Дальше». Подтверждение — снекбар «Сохранено в копилку»
/// (FR-016), потому что смена иконки на 20 пикселей легко проходит мимо глаз.
class BookmarkButton extends ConsumerWidget {
  const BookmarkButton({
    required this.bookmark,
    this.iconSize = 22,
    this.buttonSize,
    this.placement = BookmarkPlacement.reader,
    super.key,
  });

  /// Где кнопка: удаление из читалки и из открытой закладки различаются.
  final BookmarkPlacement placement;

  /// Готовая запись: вызывающий знает и текст, и происхождение.
  /// savedAt проставляется в момент нажатия, поэтому здесь он не важен.
  final Bookmark bookmark;
  final double iconSize;
  final double? buttonSize;

  void _log(WidgetRef ref, {required bool removed}) {
    final kind = bookmark.kind.name;
    ref
        .read(analyticsProvider)
        .log(
          removed
              ? AnalyticsEvent.bookmarkRemoved(kind: kind, placement: placement)
              : AnalyticsEvent.bookmarkAdded(
                  kind: kind,
                  content: bookmarkContentOf(bookmark),
                ),
        );
  }

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
      onPressed: () async {
        final changed = await ref
            .read(bookmarksProvider.notifier)
            .toggle(bookmark.copyWith(savedAt: DateTime.now()));
        if (changed) _log(ref, removed: saved);
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
      constraints: buttonSize == null
          ? null
          : BoxConstraints.tightFor(width: buttonSize, height: buttonSize),
      padding: buttonSize == null ? null : EdgeInsets.zero,
      icon: Icon(
        saved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
        size: iconSize,
        color: saved ? colors.accent : colors.homeSubtitle,
      ),
    );
  }
}

/// Тип карточки из id закладки (`quote-2026-07-17`, `basics-topic-3-page-0`);
/// у стихов, толкований и рассказов его нет.
String? bookmarkContentOf(Bookmark bookmark) {
  if (bookmark.kind != BookmarkKind.card) return null;
  final prefix = bookmark.id.split('-').first;
  const known = {'quote', 'advice', 'parable', 'reading', 'basics'};
  return known.contains(prefix) ? prefix : null;
}
