import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_name_header.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));

void main() {
  testWidgets('без ссылки на рассказ заголовок не кликабелен и без стрелки', (
    tester,
  ) async {
    const day = TodayCards(cards: [], title: 'Мц. Христи́ны Тирской');

    await tester.pumpWidget(_wrap(const DayNameHeader(day: day)));

    expect(
      find.text('Мц. Христи́ны Тирской', findRichText: true),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('со ссылкой на рассказ заголовок кликабелен и со стрелкой', (
    tester,
  ) async {
    const day = TodayCards(
      cards: [],
      title: 'Мц. Христи́ны Тирской',
      storyUrl: 'https://azbyka.ru/days/sv-hristina',
    );
    var tapped = false;

    await tester.pumpWidget(
      _wrap(DayNameHeader(day: day, onTap: () => tapped = true)),
    );

    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });

  testWidgets('без onTap заголовок не кликабелен, даже если ссылка есть', (
    tester,
  ) async {
    const day = TodayCards(
      cards: [],
      title: 'Мц. Христи́ны Тирской',
      storyUrl: 'https://azbyka.ru/days/sv-hristina',
    );

    await tester.pumpWidget(_wrap(const DayNameHeader(day: day)));

    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });
}
