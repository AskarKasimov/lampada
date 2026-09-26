import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_name_header.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  for (final fast in [false, true]) {
    testWidgets('ink охватывает весь день и нижний отступ, пост: $fast', (
      tester,
    ) async {
      final day = TodayCards(
        cards: const [],
        title: 'Название дня',
        isFast: fast,
        storyUrl: 'https://azbyka.ru/days/story',
      );
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [DayNameHeader(day: day, onTap: () => taps++)],
          ),
        ),
      );
      final ink = tester.getRect(find.byType(InkWell));
      final header = tester.getRect(find.byType(DayNameHeader));
      final title = tester.getRect(
        find.ancestor(
          of: find.byIcon(CupertinoIcons.chevron_right),
          matching: find.byType(Text),
        ),
      );
      expect(ink, header);
      expect(ink.bottom - title.bottom, 14);
      final firstText = tester.getRect(
        fast
            ? find.text('ПОСТНЫЙ ДЕНЬ')
            : find.ancestor(
                of: find.byIcon(CupertinoIcons.chevron_right),
                matching: find.byType(Text),
              ),
      );
      expect(firstText.top - ink.top, 4);
      await tester.tapAt(Offset(1, ink.bottom - 1));
      expect(taps, 1);
      if (fast) {
        await tester.tap(find.text('ПОСТНЫЙ ДЕНЬ'));
        expect(taps, 2);
      }
    });
  }

  testWidgets('без ссылки на рассказ заголовок не кликабелен и без стрелки', (
    tester,
  ) async {
    const day = TodayCards(cards: [], title: 'Мц. Христи́ны Тирской');

    await tester.pumpWidget(_wrap(const DayNameHeader(day: day)));

    expect(
      find.text('Мц. Христи́ны Тирской', findRichText: true),
      findsOneWidget,
    );
    expect(find.byIcon(CupertinoIcons.chevron_right), findsNothing);
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

    expect(find.byIcon(CupertinoIcons.chevron_right), findsOneWidget);
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

    expect(find.byIcon(CupertinoIcons.chevron_right), findsNothing);
  });
}
