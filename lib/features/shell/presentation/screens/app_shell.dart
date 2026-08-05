import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bookmarks/presentation/screens/bookmarks_screen.dart';
import '../../../daily_cards/presentation/screens/today_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../providers/shell_providers.dart';
import '../widgets/floating_nav_bar.dart';

/// Дом приложения: три вкладки. Экрана-прослойки между запуском и контентом
/// нет — корень «Сегодня» это сам день, чтобы первая мысль встречала юзера
/// сразу, а не после тапа по дашборду.
///
/// [IndexedStack], а не пересборка: уход на другую вкладку и обратно не должен
/// сбрасывать состояние экрана.
///
/// Навигация лежит в [Stack] поверх контента, а не в `bottomNavigationBar`:
/// глухая полоса снизу отрезала у экрана заметный кусок. Контент уходит под
/// капсулу, поэтому скроллящиеся вкладки оставляют снизу [kFloatingNavInset].
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(selectedTabProvider);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: tab.index,
              children: const [
                TodayScreen(),
                BookmarksScreen(),
                ProfileScreen(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNavBar(
              current: tab,
              onSelect: (selected) =>
                  ref.read(selectedTabProvider.notifier).select(selected),
            ),
          ),
        ],
      ),
    );
  }
}
