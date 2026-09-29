import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bible/presentation/screens/bible_screen.dart';
import '../../../daily_cards/presentation/providers/providers.dart';
import '../../../daily_cards/presentation/screens/plans_screen.dart';
import '../../../daily_cards/presentation/screens/today_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../reminders/presentation/widgets/reminder_scheduler.dart';
import '../providers/shell_providers.dart';
import '../widgets/floating_nav_bar.dart';

/// Дом приложения: четыре вкладки. Экрана-прослойки между запуском и контентом
/// нет — корень «Домой» это сам день, чтобы первая мысль встречала юзера
/// сразу, а не после тапа по дашборду.
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

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(selectedTabProvider);
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
                  children: const [
                    TodayScreen(),
                    BibleScreen(),
                    PlansScreen(),
                    ProfileScreen(),
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
