import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/core/widgets/selectable_share_area.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/card_content.dart';

/// Кириллический наполнитель заданной длины — не привязывает шрифт/скролл-
/// пороги к реальному контенту с azbyka.ru.
String _filler(int length) {
  final buffer = StringBuffer();
  while (buffer.length < length) {
    buffer.write('слово ');
  }
  return buffer.toString().substring(0, length);
}

DayCard _card(String body, {CardType type = CardType.advice}) =>
    DayCard(id: 'test', type: type, body: body, source: 'Тестовый источник');

// Ширина/высота как у телефона — дефолтная тестовая поверхность (~800px)
// не даёт длинному тексту перенестись на строки, чтобы переполнить 300px.
Widget _buildApp(DayCard card) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: SizedBox(width: 320, height: 300, child: CardContent(card: card)),
  ),
);

double? _fontSizeOf(WidgetTester tester, String body) =>
    tester.widget<Text>(find.text(body)).style?.fontSize;

void main() {
  testWidgets(
    'короткая карточка (≤200 символов): шрифт 24px, без намёка на скролл',
    (tester) async {
      final card = _card(_filler(50));
      await tester.pumpWidget(_buildApp(card));
      await tester.pump();

      expect(_fontSizeOf(tester, card.body), 24);
      expect(find.byIcon(CupertinoIcons.chevron_down), findsNothing);
    },
  );

  testWidgets('карточка 300 символов сохраняет крупный шрифт', (tester) async {
    final card = _card(_filler(300));
    await tester.pumpWidget(_buildApp(card));
    await tester.pump();

    expect(_fontSizeOf(tester, card.body), 24);
  });

  testWidgets(
    'длинная карточка (>500 символов): крупный шрифт, намёк на скролл виден',
    (tester) async {
      final card = _card(_filler(600));
      await tester.pumpWidget(_buildApp(card));
      await tester.pump();

      expect(_fontSizeOf(tester, card.body), 24);
      expect(find.byIcon(CupertinoIcons.chevron_down), findsOneWidget);
    },
  );

  testWidgets('после скролла длинной карточки до конца намёк исчезает', (
    tester,
  ) async {
    final card = _card(_filler(600));
    await tester.pumpWidget(_buildApp(card));
    await tester.pump();
    expect(find.byIcon(CupertinoIcons.chevron_down), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -2000),
    );
    await tester.pump();

    expect(find.byIcon(CupertinoIcons.chevron_down), findsNothing);
  });

  testWidgets('в читалке карточка показывает первые 200 символов и троеточие', (
    tester,
  ) async {
    final card = _card(_filler(3000));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 844,
            child: CardContent(card: card, showBadge: false, scrollable: false),
          ),
        ),
      ),
    );
    await tester.pump();

    final preview = '${card.body.substring(0, 200)}…';
    final text = tester.widget<Text>(find.text(preview));
    expect(text.style?.fontSize, 24);
    expect(find.text(card.body), findsNothing);
    expect(find.byTooltip('Открыть полный текст'), findsNothing);
  });

  testWidgets('в Основах повторные переводы строк схлопываются в один', (
    tester,
  ) async {
    const displayed = 'Первый абзац\nВторой абзац\nТретий абзац';
    final card = _card(
      'Первый абзац\n\nВторой абзац\n\n\nТретий абзац',
      type: CardType.basics,
    );

    await tester.pumpWidget(_buildApp(card));
    await tester.pump();

    expect(find.text(displayed), findsOneWidget);
    expect(find.text(card.body), findsNothing);
  });

  testWidgets('в Основах лимит превью считается после схлопывания переносов', (
    tester,
  ) async {
    final displayed = '${'а' * 199}\n';
    final card = _card('$displayed\n', type: CardType.basics);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 844,
            child: CardContent(card: card, showBadge: false, scrollable: false),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(displayed), findsOneWidget);
    expect(find.text('$displayed…'), findsNothing);
  });

  testWidgets('под текстом всегда подпись источника', (tester) async {
    final card = _card(_filler(50));
    await tester.pumpWidget(_buildApp(card));
    await tester.pump();

    expect(find.text('— Тестовый источник'), findsOneWidget);
  });

  testWidgets('текст карточки можно выделить и отправить', (tester) async {
    await tester.pumpWidget(_buildApp(_card(_filler(50))));

    expect(find.byType(SelectableShareArea), findsOneWidget);
  });
}
