import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/analytics_event.dart';
import 'package:lampada/core/analytics/screen_tracker.dart';

/// Упрощённая оболочка: две вкладки со своими навигаторами в IndexedStack,
/// как в AppShell. Неактивная вкладка остаётся построенной.
class _Host extends StatefulWidget {
  const _Host({super.key});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final first = GlobalKey<NavigatorState>();
  final second = GlobalKey<NavigatorState>();
  var active = 0;

  void select(int index) => setState(() => active = index);

  NavigatorState get activeNavigator =>
      (active == 0 ? first : second).currentState!;

  Route<dynamic> get route => ModalRoute.of(context)!;

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: active,
    children: [
      Navigator(
        key: first,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const AnalyticsScreen(
            screen: AppScreen.home,
            child: Text('home'),
          ),
        ),
      ),
      Navigator(
        key: second,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const AnalyticsScreen(
            screen: AppScreen.profile,
            child: Text('profile'),
          ),
        ),
      ),
    ],
  );
}

void main() {
  late ProviderContainer container;
  final hostKey = GlobalKey<_HostState>();

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  Future<void> pumpHost(WidgetTester tester) => tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: _Host(key: hostKey)),
    ),
  );

  ScreenSnapshot? current() {
    final host = hostKey.currentState!;
    return container
        .read(screenTrackerProvider)
        .current(hostRoute: host.route, tabNavigator: host.activeNavigator);
  }

  testWidgets('без открытых экранов текущий это корень активной вкладки', (
    tester,
  ) async {
    await pumpHost(tester);

    expect(current()?.screen, AppScreen.home);
    hostKey.currentState!.select(1);
    await tester.pump();
    expect(current()?.screen, AppScreen.profile);
  });

  testWidgets('открытый во вкладке экран перекрывает её корень', (
    tester,
  ) async {
    await pumpHost(tester);
    hostKey.currentState!.first.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const AnalyticsScreen(
          screen: AppScreen.wisdom,
          child: Text('wisdom'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(current()?.screen, AppScreen.wisdom);
    // Открытый экран другой вкладки не считается, пока она не выбрана.
    hostKey.currentState!.select(1);
    await tester.pump();
    expect(current()?.screen, AppScreen.profile);

    hostKey.currentState!.select(0);
    await tester.pump();
    hostKey.currentState!.first.currentState!.pop();
    await tester.pumpAndSettle();
    expect(current()?.screen, AppScreen.home);
  });

  testWidgets('экран поверх оболочки важнее активной вкладки', (tester) async {
    await pumpHost(tester);
    Navigator.of(tester.element(find.text('home')), rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => const AnalyticsScreen(
          screen: AppScreen.interpretation,
          child: Text('sheet'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(current()?.screen, AppScreen.interpretation);
  });

  testWidgets('читалка сообщает индекс страницы, событие нумерует с единицы', (
    tester,
  ) async {
    await pumpHost(tester);
    hostKey.currentState!.first.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const AnalyticsScreen(
          screen: AppScreen.story,
          child: Text('story'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(current()?.page, isNull);

    AnalyticsScreen.reportPage(
      tester.element(find.text('story')),
      page: 1,
      pagesTotal: 7,
    );

    final snapshot = current()!;
    expect(snapshot.screen, AppScreen.story);
    expect(snapshot.page, 2);
    expect(snapshot.pagesTotal, 7);
  });
}
