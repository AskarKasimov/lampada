import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/screens/full_card_text_screen.dart';

void main() {
  testWidgets('полный текст Основ не оставляет двойные переводы строк', (
    tester,
  ) async {
    const displayed = 'Первый абзац\nВторой абзац';
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

    expect(find.text(displayed), findsOneWidget);
    expect(find.text(card.body), findsNothing);
  });
}
