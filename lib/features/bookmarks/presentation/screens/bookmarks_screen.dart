import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../shell/presentation/widgets/floating_nav_bar.dart';
import '../providers/providers.dart';
import '../widgets/bookmark_tile.dart';
import '../widgets/bookmarks_empty_view.dart';

/// Экран «Закладки» — «Копилка смыслов». Локальная, без аккаунта (FR-017).
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({this.onClose, super.key});

  /// Модальный вход в копилку должен явно вернуть на предыдущий экран: жест назад
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
          padding: const EdgeInsets.only(bottom: kFloatingNavInset),
          itemCount: bookmarks.length,
          separatorBuilder: (context, index) => Padding(
            padding: AppSpacing.of(context).horizontal,
            child: Divider(height: 1, color: colors.chipUnreadBorder),
          ),
          itemBuilder: (context, index) {
            final bookmark = bookmarks[index];
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
        // Копилка начинается сразу под шапкой; Material 3 по умолчанию
        // тонирует AppBar после первого пикселя прокрутки, и заголовок
        // начинает выглядеть отдельной плашкой.
        backgroundColor: colors.background,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: const Text('Копилка смыслов'),
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: onClose, color: colors.homeSubtitle),
      ),
      body: body,
    );
  }
}
