import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Вкладки нижней навигации в порядке показа. Порядок значений = порядок
/// в таб-баре, индекс enum использует [AppShell] напрямую.
///
/// Отдельной вкладки календаря нет: главная всегда показывает сегодняшний
/// день, выбора даты в приложении нет.
enum ShellTab { today, bible, profile }

/// Активная вкладка. Провайдер, а не локальный State шелла, потому что
/// переключать её должны снаружи: тап по пушу и по виджету обязаны открывать
/// вкладку «Главная» независимо от того, где юзер был в прошлый раз (FR-015).
final selectedTabProvider = NotifierProvider<SelectedTabNotifier, ShellTab>(
  SelectedTabNotifier.new,
);

class SelectedTabNotifier extends Notifier<ShellTab> {
  @override
  ShellTab build() => ShellTab.today;

  void select(ShellTab tab) => state = tab;
}
