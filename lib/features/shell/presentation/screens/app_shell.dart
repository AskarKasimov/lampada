import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bible/presentation/screens/bible_tab_screen.dart';
import '../../../daily_cards/presentation/providers/providers.dart';
import '../../../daily_cards/presentation/screens/today_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../reminders/presentation/widgets/reminder_scheduler.dart';
import '../providers/shell_providers.dart';
import '../widgets/floating_nav_bar.dart';

/// Дом приложения: три вкладки. Экрана-прослойки между запуском и контентом
/// нет — корень вкладки «Главная» это день с входом в «Мудрость дня» и личный курс.
///
/// [IndexedStack], а не пересборка: уход на другую вкладку и обратно не должен
/// сбрасывать состояние экрана.
///
/// Навигация лежит в [Stack] поверх контента, а не в `bottomNavigationBar`:
/// глухая полоса снизу отрезала у экрана заметный кусок. Контент уходит под
/// капсулу, поэтому скроллящиеся вкладки оставляют снизу [kFloatingNavInset].
///
/// Библия — обычная вкладка со своим [Navigator]: каталог и справка
/// открываются внутри неё, и навбар остаётся виден.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  Timer? _dayTimer;
  final _bibleNavigatorKey = GlobalKey<NavigatorState>();

  /// Читалка Библии грузит главу при построении, поэтому вкладку строим
  /// только после первого входа, а не на старте приложения.
  bool _bibleVisited = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleDayChange();
  }

  void _scheduleDayChange() {
    _dayTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _dayTimer = Timer(tomorrow.difference(now), _refreshDay);
  }

  void _refreshDay() {
    if (!mounted) return;
    // Отметка темы относится к дате: после полуночи ежедневный вход возвращается.
    ref.invalidate(dayProgressProvider);
    setState(() {});
    _scheduleDayChange();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshDay();
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget _bibleTab(bool active) => NavigatorPopHandler(
    // Системный «назад» на Android закрывает каталог внутри вкладки,
    // а не всё приложение.
    enabled: active,
    onPopWithResult: (_) => _bibleNavigatorKey.currentState?.maybePop(),
    child: Builder(
      builder: (context) {
        final media = MediaQuery.of(context);
        final bottom = floatingNavBarExtent(context);
        // Читалка ставит кнопки от нижнего safe area, а капсула навбара
        // перекрыла бы их: для вкладки низ экрана заканчивается над ней.
        return MediaQuery(
          data: media.copyWith(
            padding: media.padding.copyWith(bottom: bottom),
            viewPadding: media.viewPadding.copyWith(bottom: bottom),
          ),
          child: Navigator(
            key: _bibleNavigatorKey,
            onGenerateRoute: (_) =>
                MaterialPageRoute<void>(builder: (_) => const BibleTabScreen()),
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(selectedTabProvider);
    if (tab == ShellTab.bible) _bibleVisited = true;
    return ReminderScheduler(
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: FloatingNavInset(
                inset: kFloatingNavInset,
                child: IndexedStack(
                  index: tab.index,
                  children: [
                    const TodayScreen(),
                    if (_bibleVisited)
                      _bibleTab(tab == ShellTab.bible)
                    else
                      const SizedBox.shrink(),
                    const ProfileScreen(),
                  ],
                ),
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
      ),
    );
  }
}
