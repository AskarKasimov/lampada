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
/// нет — корень «Домой» это день с входом в «Мудрость дня» и личный курс.
///
/// [IndexedStack], а не пересборка: уход на другую вкладку и обратно не должен
/// сбрасывать состояние экрана.
///
/// Навигация лежит в [Stack] поверх контента, а не в `bottomNavigationBar`:
/// глухая полоса снизу отрезала у экрана заметный кусок. Контент уходит под
/// капсулу, поэтому скроллящиеся вкладки оставляют снизу [kFloatingNavInset].
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  Timer? _dayTimer;
  bool _bibleOpen = false;
  Route<void>? _bibleRoute;
  ShellTab _backgroundTab = ShellTab.today;

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

  Future<void> _openBible() async {
    if (!mounted || ref.read(selectedTabProvider) != ShellTab.bible) {
      _bibleOpen = false;
      return;
    }
    final returnTab = _backgroundTab;
    final route = MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (routeContext) => FloatingNavInset(
        inset: 0,
        child: Scaffold(
          body: BibleTabScreen(onClose: () => Navigator.of(routeContext).pop()),
        ),
      ),
    );
    _bibleRoute = route;
    await Navigator.of(context).push<void>(route);
    _bibleRoute = null;
    _bibleOpen = false;
    if (mounted && ref.read(selectedTabProvider) == ShellTab.bible) {
      ref.read(selectedTabProvider.notifier).select(returnTab);
    }
  }

  void _closeBibleForTabChange() {
    final route = _bibleRoute;
    if (!mounted ||
        route == null ||
        !route.isActive ||
        ref.read(selectedTabProvider) == ShellTab.bible) {
      return;
    }
    final navigator = Navigator.of(context);
    // Переход по уведомлению закрывает также каталог поверх читалки.
    navigator.popUntil((current) => identical(current, route));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedTabProvider, (previous, next) {
      if (previous == ShellTab.bible && next != ShellTab.bible) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _closeBibleForTabChange(),
        );
      }
    });
    final tab = ref.watch(selectedTabProvider);
    // Читалка накрывает прежнюю вкладку, сохраняя её и при закрытии.
    if (tab != ShellTab.bible) _backgroundTab = tab;
    if (tab == ShellTab.bible && !_bibleOpen) {
      _bibleOpen = true;
      // Маршрут открывается после кадра, чтобы не менять Navigator в build.
      WidgetsBinding.instance.addPostFrameCallback((_) => _openBible());
    }
    return ReminderScheduler(
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: FloatingNavInset(
                inset: kFloatingNavInset,
                child: IndexedStack(
                  index: tab == ShellTab.bible
                      ? _backgroundTab.index
                      : tab.index,
                  children: const [
                    TodayScreen(),
                    SizedBox.shrink(),
                    ProfileScreen(),
                  ],
                ),
              ),
            ),
            if (tab != ShellTab.bible)
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
