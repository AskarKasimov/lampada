import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../shell/presentation/widgets/floating_nav_bar.dart';
import '../providers/providers.dart';
import '../widgets/bookmark_tile.dart';
import '../widgets/bookmarks_empty_view.dart';

/// Экран «Закладки» — «Копилка смыслов». Локальная, без аккаунта (FR-017).
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({this.onClose, super.key});

  /// Модальный вход в копилку должен явно вернуть на «Сегодня»: жест назад
  /// на iOS для fullscreenDialog недоступен.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookmarksProvider);
    final colors = AppColorsExtension.of(context);

    final body = async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      // Сбой локального хранилища — не повод пугать: копилка просто пуста.
      error: (_, _) => const BookmarksEmptyView(),
      data: (bookmarks) {
        if (bookmarks.isEmpty) return const BookmarksEmptyView();

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, kFloatingNavInset),
          itemCount: bookmarks.length + 1,
          separatorBuilder: (context, index) => index == 0
              ? const SizedBox.shrink()
              : Divider(height: 1, color: colors.chipUnreadBorder),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'КОПИЛКА СМЫСЛОВ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.9,
                    color: colors.todayLabel,
                  ),
                ),
              );
            }
            final bookmark = bookmarks[index - 1];
            return BookmarkTile(
              bookmark: bookmark,
              onRemove: () async {
                final removed = await ref
                    .read(bookmarksProvider.notifier)
                    .remove(bookmark.id);
                if (!removed && context.mounted) {
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    const SnackBar(
                      content: Text('Не удалось удалить закладку'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return removed;
              },
            );
          },
        );
      },
    );

    if (onClose == null) return body;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Закладки'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(CupertinoIcons.xmark),
            tooltip: 'Закрыть',
          ),
        ],
      ),
      body: body,
    );
  }
}
