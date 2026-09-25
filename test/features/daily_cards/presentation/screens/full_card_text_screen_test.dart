import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/screens/full_card_text_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/card_content.dart';

void main() {
  testWidgets('свайп в сторону закрывает полный текст', (tester) async {
    const card = DayCard(
      id: 'advice-1',
      type: CardType.advice,
      body: 'Текст карточки',
      source: 'Тестовый источник',
    );
    await _pumpRouteHost(tester, card);

    await tester.drag(find.byType(FullCardTextScreen), const Offset(180, 0));
    await tester.pumpAndSettle();

    expect(find.byType(FullCardTextScreen), findsNothing);
  });

  testWidgets('свайп вниз с верхней границы закрывает полный текст', (
    tester,
  ) async {
    const card = DayCard(
      id: 'advice-1',
      type: CardType.advice,
      body: 'Текст карточки',
      source: 'Тестовый источник',
    );
    await _pumpRouteHost(tester, card);

    await tester.drag(find.byType(FullCardTextScreen), const Offset(0, 180));
    await tester.pumpAndSettle();

    expect(find.byType(FullCardTextScreen), findsNothing);
  });

  testWidgets('свайп вверх прокручивает текст, пока не достигнут его конец', (
    tester,
  ) async {
    final card = DayCard(
      id: 'advice-1',
      type: CardType.advice,
      body: List.filled(300, 'Длинный текст').join(' '),
      source: 'Тестовый источник',
    );
    await _pumpRouteHost(tester, card);

    await tester.drag(find.byType(FullCardTextScreen), const Offset(0, -180));
    await tester.pumpAndSettle();

    expect(find.byType(FullCardTextScreen), findsOneWidget);
  });

  testWidgets('свайп вверх с нижней границы закрывает полный текст', (
    tester,
  ) async {
    final card = DayCard(
      id: 'advice-1',
      type: CardType.advice,
      body: List.filled(300, 'Длинный текст').join(' '),
      source: 'Тестовый источник',
    );
    await _pumpRouteHost(tester, card);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -9999),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(FullCardTextScreen), const Offset(0, -180));
    await tester.pumpAndSettle();

    expect(find.byType(FullCardTextScreen), findsNothing);
  });

  testWidgets('полный текст использует сетку сокращённой карточки', (
    tester,
  ) async {
    const card = DayCard(
      id: 'advice-1',
      type: CardType.advice,
      body: 'Текст карточки',
      source: 'Тестовый источник',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const FullCardTextScreen(card: card),
      ),
    );

    final safeArea = tester.widget<SafeArea>(find.byType(SafeArea));
    final contentPadding = tester
        .widgetList<Padding>(find.byType(Padding))
        .singleWhere((padding) => padding.child is CardContent);
    final closePosition = tester.widget<Positioned>(
      find.ancestor(
        of: find.byTooltip('Закрыть полный текст'),
        matching: find.byType(Positioned),
      ),
    );

    expect(safeArea.left, isFalse);
    expect(safeArea.right, isFalse);
    expect(contentPadding.padding, const EdgeInsets.fromLTRB(33, 48, 24, 24));
    expect(closePosition.top, 0);
    expect(closePosition.right, 0);
  });

  testWidgets('полный текст раскрывается масштабом и прозрачностью', (
    tester,
  ) async {
    const card = DayCard(
      id: 'advice-1',
      type: CardType.advice,
      body: 'Текст карточки',
      source: 'Тестовый источник',
    );
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );

    final transition = FullCardTextRoute(card: card).buildTransitions(
      context,
      const AlwaysStoppedAnimation(0.5),
      const AlwaysStoppedAnimation(0),
      const SizedBox(),
    );

    expect(transition, isA<FadeTransition>());
    expect((transition as FadeTransition).child, isA<ScaleTransition>());
  });

  testWidgets('полный текст Основ сохраняет двойные переводы строк', (
    tester,
  ) async {
    const card = DayCard(
      id: 'basics-topic-1',
      type: CardType.basics,
      body: 'Первый абзац\n\nВторой абзац',
      source: 'Тестовый источник',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const FullCardTextScreen(card: card),
      ),
    );
    await tester.pump();

    expect(find.text(card.body), findsOneWidget);
  });

  testWidgets('полный текст Евангелия повторяет типографику карточки', (
    tester,
  ) async {
    const card = DayCard(
      id: 'reading-12:1',
      type: CardType.reading,
      body:
          'И начал говорить им притчами: некоторый человек насадил виноградник',
      source: 'Мк.12:1',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const FullCardTextScreen(card: card),
      ),
    );

    final text = tester.widget<Text>(find.text(card.body));

    expect(text.style?.fontSize, 27);
    expect(text.style?.height, 1.5);
  });
}

Future<void> _pumpRouteHost(WidgetTester tester, DayCard card) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () =>
              Navigator.of(context).push(FullCardTextRoute(card: card)),
          child: const Text('Исходный экран'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Исходный экран'));
  await tester.pumpAndSettle();
}
