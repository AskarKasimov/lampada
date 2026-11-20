import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_event.dart';

/// Один трекер на приложение: экраны регистрируются в нём, а оболочка при
/// уходе в фон спрашивает, какой из них юзер видел последним.
final screenTrackerProvider = Provider<ScreenTracker>(
  (ref) => ScreenTracker.instance,
);

/// Экран и страница читалки на момент вопроса.
class ScreenSnapshot {
  const ScreenSnapshot(this.screen, {this.page, this.pagesTotal});

  final AppScreen screen;
  final int? page;
  final int? pagesTotal;
}

class ScreenTracker {
  ScreenTracker._();

  /// Экраны регистрируются без ProviderScope: многие из них тестируются
  /// поодиночке, а размонтированный экран сам убирает свою запись.
  static final instance = ScreenTracker._();

  final _entries = <_ScreenEntry>[];

  /// Видимый экран.
  ///
  /// Вкладки живут в IndexedStack и не размонтируются, а открытые маршруты
  /// под верхним остаются построенными, поэтому «последний построенный» не
  /// годится. Сначала ищем экран поверх оболочки ([hostRoute] — её маршрут
  /// в корневом навигаторе), затем верхний экран активной вкладки
  /// [tabNavigator]. Маршруты в навигаторе открываются по порядку, значит
  /// позже зарегистрированный экран лежит выше.
  ScreenSnapshot? current({
    required Route<dynamic>? hostRoute,
    required NavigatorState? tabNavigator,
  }) {
    _ScreenEntry? topIn(bool Function(Route<dynamic> route) matches) {
      for (final entry in _entries.reversed) {
        final route = entry.route;
        if (route != null && route.isActive && matches(route)) return entry;
      }
      return null;
    }

    final rootNavigator = hostRoute?.navigator;
    final entry =
        (rootNavigator == null
            ? null
            : topIn((r) => r.navigator == rootNavigator && r != hostRoute)) ??
        (tabNavigator == null
            ? null
            : topIn((r) => r.navigator == tabNavigator));
    if (entry == null) return null;
    return ScreenSnapshot(
      entry.screen,
      page: entry.page,
      pagesTotal: entry.pagesTotal,
    );
  }

  void _add(_ScreenEntry entry) => _entries.add(entry);

  void _remove(_ScreenEntry entry) => _entries.remove(entry);
}

class _ScreenEntry {
  _ScreenEntry(this.screen);

  AppScreen screen;
  Route<dynamic>? route;
  int? page;
  int? pagesTotal;

  void setPage(int index, int total) {
    page = index + 1;
    pagesTotal = total;
  }
}

/// Отмечает поддерево как экран [screen] для события ухода в фон.
///
/// Страницу читалка передаёт через [page] и [pagesTotal], если сама строит
/// этот виджет, или через [reportPage] из глубины своего поддерева.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    required this.screen,
    required this.child,
    this.page,
    this.pagesTotal,
    super.key,
  });

  final AppScreen screen;
  final Widget child;

  /// Индекс страницы с нуля.
  final int? page;
  final int? pagesTotal;

  /// Читалка сообщает текущую страницу ближайшего экрана; [page] с нуля.
  /// Вне [AnalyticsScreen] вызов ничего не делает: виджеты читалок
  /// переиспользуются и в тестах строятся без него.
  static void reportPage(
    BuildContext context, {
    required int page,
    required int pagesTotal,
  }) => context
      .getInheritedWidgetOfExactType<_AnalyticsScreenScope>()
      ?.entry
      .setPage(page, pagesTotal);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final _entry = _ScreenEntry(widget.screen);
  final _tracker = ScreenTracker.instance;

  @override
  void initState() {
    super.initState();
    _applyPage();
    _tracker._add(_entry);
  }

  void _applyPage() {
    final page = widget.page;
    final total = widget.pagesTotal;
    if (page != null && total != null) _entry.setPage(page, total);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _entry.route = ModalRoute.of(context);
  }

  @override
  void didUpdateWidget(AnalyticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry.screen = widget.screen;
    _applyPage();
  }

  @override
  void dispose() {
    _tracker._remove(_entry);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _AnalyticsScreenScope(entry: _entry, child: widget.child);
}

class _AnalyticsScreenScope extends InheritedWidget {
  const _AnalyticsScreenScope({required this.entry, required super.child});

  final _ScreenEntry entry;

  @override
  bool updateShouldNotify(_AnalyticsScreenScope oldWidget) => false;
}
