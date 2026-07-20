import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/card_content.dart';

/// Кириллический наполнитель заданной длины — для проверки
/// шрифт/скролл-порогов без привязки к реальному контенту с azbyka.ru.
String _filler(int length) {
  final buffer = StringBuffer();
  while (buffer.length < length) {
    buffer.write('слово ');
  }
  return buffer.toString().substring(0, length);
}

DayCard _card(String body, {CardType type = CardType.advice}) => DayCard(
      id: 'test',
      type: type,
      body: body,
      source: 'Тестовый источник',
    );

const _questionHint =
    'Пусть этот вопрос поживёт с вами весь день — в дороге, в очереди, '
    'в тишине перед сном.';

// Ширина/высота как у телефона — иначе дефолтная тестовая поверхность
// (~800px) не даёт длинному тексту перенестись на достаточно строк,
// чтобы гарантированно переполнить 300px высоты.
Widget _buildApp(DayCard card) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: 320,
          height: 300,
          child: CardContent(card: card),
        ),
      ),
    );

double? _fontSizeOf(WidgetTester tester, String body) =>
    tester.widget<Text>(find.text(body)).style?.fontSize;

void main() {
  testWidgets('короткая карточка (≤220 символов): шрифт 24px, без намёка на скролл',
      (tester) async {
    final card = _card(_filler(50));
    await tester.pumpWidget(_buildApp(card));
    await tester.pump();

    expect(_fontSizeOf(tester, card.body), 24);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
  });

  testWidgets('карточка 300 символов: шрифт 21px', (tester) async {
    final card = _card(_filler(300));
    await tester.pumpWidget(_buildApp(card));
    await tester.pump();

    expect(_fontSizeOf(tester, card.body), 21);
  });

  testWidgets('длинная карточка (>500 символов): шрифт 18px, намёк на скролл виден',
      (tester) async {
    final card = _card(_filler(600));
    await tester.pumpWidget(_buildApp(card));
    await tester.pump();

    expect(_fontSizeOf(tester, card.body), 18);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
  });

  testWidgets('после скролла длинной карточки до конца намёк исчезает',
      (tester) async {
    final card = _card(_filler(600));
    await tester.pumpWidget(_buildApp(card));
    await tester.pump();
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -2000));
    await tester.pump();

    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
  });

  testWidgets('карточка вопроса — фиксированное напутствие под текстом',
      (tester) async {
    final card = _card('В чём смысл поста?', type: CardType.question);
    await tester.pumpWidget(_buildApp(card));
    await tester.pump();

    expect(find.text(_questionHint), findsOneWidget);
  });

  testWidgets('карточка вопроса — без подписи источника, перегруз ни к чему',
      (tester) async {
    final card = _card('В чём смысл поста?', type: CardType.question);
    await tester.pumpWidget(_buildApp(card));
    await tester.pump();

    expect(find.textContaining(card.source), findsNothing);
  });

  testWidgets('на остальных типах напутствия нет', (tester) async {
    final card = _card(_filler(50));
    await tester.pumpWidget(_buildApp(card));
    await tester.pump();

    expect(find.text(_questionHint), findsNothing);
  });
}
