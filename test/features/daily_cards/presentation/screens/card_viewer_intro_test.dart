import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/navigation/bottom_up_modal_route.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/screens/card_viewer_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/section_pill_intro.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/swipe_up_hint.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _cards = [
  DayCard(id: 'q', type: CardType.quote, body: 'Мысль', source: 'Источник'),
  DayCard(id: 'a', type: CardType.advice, body: 'Совет', source: 'Источник'),
];

void main() {
  late SharedPreferences prefs;
  late List<CardType> introduced;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    introduced = [];
  });

  CardViewerScreen viewer(Set<CardType> introduce) => CardViewerScreen(
    cards: _cards,
    startIndex: 0,
    date: DateTime(2026, 11, 17),
    recordProgress: false,
    recordRead: false,
    introduceSections: introduce,
    onSectionIntroduced: introduced.add,
  );

  Widget app({Set<CardType> introduce = const {}, bool reduceMotion = false}) =>
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(400, 800),
              disableAnimations: reduceMotion,
            ),
            child: viewer(introduce),
          ),
        ),
      );

  double pillScale(WidgetTester tester) => tester
      .widget<Transform>(
        find.descendant(
          of: find.byType(SectionPillIntro),
          matching: find.byType(Transform),
        ),
      )
      .transform
      .getMaxScaleOnAxis();

  double scrolled(WidgetTester tester) => tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position
      .pixels;

  /// Время идёт покадрово: анимация отсчитывает его от первого кадра.
  Future<void> pumpFor(WidgetTester tester, Duration span) async {
    for (var i = 0; i < span.inMilliseconds ~/ 16; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// Текст карточки виден: ни один предок не прячет его прозрачностью.
  bool textVisible(WidgetTester tester, String text) => tester
      .widgetList<Opacity>(
        find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
      )
      .every((o) => o.opacity == 1);

  testWidgets('новый раздел начинается с чуть крупной плашки над текстом', (
    tester,
  ) async {
    await tester.pumpWidget(app(introduce: {CardType.quote, CardType.advice}));
    await pumpFor(tester, const Duration(milliseconds: 500));
    expect(pillScale(tester), greaterThan(1.3));
    expect(textVisible(tester, 'Мысль'), isTrue);

    await tester.pumpAndSettle();
    expect(pillScale(tester), 1);
    expect(introduced, [CardType.quote]);
  });

  testWidgets('после плашки палец показывает свайп, текст на месте', (
    tester,
  ) async {
    await tester.pumpWidget(app(introduce: {CardType.quote}));
    await pumpFor(tester, const Duration(milliseconds: 500));
    // Пока плашка крупная, пальца нет.
    expect(find.byType(SwipeUpHint), findsNothing);

    await pumpFor(tester, const Duration(milliseconds: 1500));
    expect(find.byType(SwipeUpHint), findsOneWidget);
    // Палец под текстом, а не поверх него.
    expect(
      tester.getCenter(find.byType(SwipeUpHint)).dy,
      greaterThan(tester.getCenter(find.text('Мысль')).dy),
    );

    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(scrolled(tester), 0);
    }
    await tester.pumpAndSettle();
    expect(find.byType(SwipeUpHint), findsNothing);
  });

  testWidgets('касание убирает палец', (tester) async {
    await tester.pumpWidget(app(introduce: {CardType.quote}));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(find.byType(SwipeUpHint), findsOneWidget);

    final gesture = await tester.startGesture(const Offset(200, 400));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(find.byType(SwipeUpHint), findsNothing);
  });

  testWidgets('следующий раздел тоже представляется при первом показе', (
    tester,
  ) async {
    await tester.pumpWidget(app(introduce: {CardType.quote, CardType.advice}));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(0, -600));
    await pumpFor(tester, const Duration(milliseconds: 800));
    expect(pillScale(tester), greaterThan(1.3));
    await tester.pumpAndSettle();
    expect(introduced, [CardType.quote, CardType.advice]);
  });

  testWidgets('выехавший экран ждёт конца перехода', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                BottomUpModalRoute<void>(
                  builder: (_) => viewer(const {CardType.quote}),
                ),
              ),
              child: const Text('открыть'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('открыть'));
    await pumpFor(tester, const Duration(milliseconds: 300));
    // Экран ещё выезжает: знакомство не началось.
    expect(pillScale(tester), 1);
    expect(introduced, isEmpty);

    await pumpFor(tester, const Duration(milliseconds: 800));
    expect(pillScale(tester), greaterThan(1.3));
    await tester.pumpAndSettle();
  });

  testWidgets('знакомый раздел открывается сразу, без пальца', (tester) async {
    await tester.pumpWidget(app());
    for (var i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(pillScale(tester), 1);
      expect(scrolled(tester), 0);
      expect(find.byType(SwipeUpHint), findsNothing);
    }
    expect(introduced, isEmpty);
  });

  testWidgets('«Уменьшение движения» обходится без анимации', (tester) async {
    await tester.pumpWidget(
      app(introduce: {CardType.quote}, reduceMotion: true),
    );
    for (var i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(pillScale(tester), 1);
      expect(find.byType(SwipeUpHint), findsNothing);
    }
    expect(introduced, [CardType.quote]);
  });
}
