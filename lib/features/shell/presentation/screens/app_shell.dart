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
/// «Главная» и «Библия» — вкладки со своим [Navigator]: «Мудрость дня»,
/// «Основы веры», каталог и справка открываются внутри вкладки сдвигом
/// вправо, и навбар остаётся виден. Полноэкранными поверх шелла остаются
/// только системные по смыслу экраны (разрешение на напоминания, рассказ
/// о дне) и шторки — они уходят в корневой навигатор.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  Timer? _dayTimer;
  final _homeNavigatorKey = GlobalKey<NavigatorState>();
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

  Widget _tabNavigator({
    required GlobalKey<NavigatorState> navigatorKey,
    required bool active,
    required Widget root,
  }) => NavigatorPopHandler(
    // Системный «назад» на Android закрывает экран внутри вкладки,
    // а не всё приложение.
    enabled: active,
    onPopWithResult: (_) => navigatorKey.currentState?.maybePop(),
    child: Builder(
      builder: (context) {
        final media = MediaQuery.of(context);
        final bottom = floatingNavBarExtent(context);
        // Читалки ставят кнопки от нижнего safe area, а капсула навбара
        // перекрыла бы их: для вкладки низ экрана заканчивается над ней.
        // Списки с явным padding от FloatingNavInset это не затрагивает.
        return MediaQuery(
          data: media.copyWith(
            padding: media.padding.copyWith(bottom: bottom),
            viewPadding: media.viewPadding.copyWith(bottom: bottom),
          ),
          child: Navigator(
            key: navigatorKey,
            onGenerateRoute: (_) =>
                MaterialPageRoute<void>(builder: (_) => root),
          ),
        );
      },
    ),
  );

  void _select(ShellTab current, ShellTab selected) {
    // Повторный тап по активной вкладке возвращает к её началу, как
    // в системном таббаре iOS.
    if (selected == current) {
      final navigator = switch (selected) {
        ShellTab.today => _homeNavigatorKey.currentState,
        ShellTab.bible => _bibleNavigatorKey.currentState,
        ShellTab.profile => null,
      };
      navigator?.popUntil((route) => route.isFirst);
      return;
    }
    ref.read(selectedTabProvider.notifier).select(selected);
  }

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
                    _tabNavigator(
                      navigatorKey: _homeNavigatorKey,
                      active: tab == ShellTab.today,
                      root: const TodayScreen(),
                    ),
                    if (_bibleVisited)
                      _tabNavigator(
                        navigatorKey: _bibleNavigatorKey,
                        active: tab == ShellTab.bible,
                        root: const BibleTabScreen(),
                      )
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
                onSelect: (selected) => _select(tab, selected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
