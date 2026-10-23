import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/analytics_event.dart';
import 'package:lampada/core/analytics/analytics_provider.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/bible/domain/entities/daily_verse.dart';
import 'package:lampada/features/bible/presentation/providers/providers.dart';
import 'package:lampada/features/bible/presentation/widgets/verse_of_day_card.dart';
import 'package:lampada/features/bookmarks/presentation/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/fake_analytics.dart';

const _verse = DailyVerse(
  book: 'Ps',
  chapter: 22,
  verse: 1,
  text: 'Господь — Пастырь мой; я ни в чем не буду нуждаться.',
);

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Future<DailyVerse> Function()? load,
  }) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        analyticsProvider.overrideWithValue(FakeAnalytics()),
        verseOfDayProvider.overrideWith(
          (ref, key) => (load ?? () async => _verse)(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ListView(
              children: [VerseOfDaySection(date: DateTime(2026, 10, 23))],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('карточка показывает ссылку и текст стиха без плашки перевода', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Стих дня'), findsOneWidget);
    expect(find.text('Пс. 22:1'), findsOneWidget);
    // Название карточки набрано как названия плиток главной, ссылка как их
    // подписи: на главной один набор заголовков.
    final title = tester.widget<Text>(find.text('Стих дня')).style!;
    expect(title.fontFamily, 'Lora');
    expect(title.fontSize, AppTheme.cardTitleSize);
    expect(
      tester.widget<Text>(find.text('Пс. 22:1')).style?.fontSize,
      AppTheme.cardCaptionStyle(tester.element(find.text('Пс. 22:1'))).fontSize,
    );
    expect(find.text('Синодальный'), findsNothing);
    expect(find.text(_verse.text), findsOneWidget);
    // Сам стих набран Lora, как всё, что читают.
    expect(
      tester.widget<Text>(find.text(_verse.text)).style?.fontFamily,
      'Lora',
    );
  });

  testWidgets('под карточкой лёгкая тень, подложка непрозрачная', (
    tester,
  ) async {
    await pump(tester);

    final card = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(VerseOfDayCard),
            matching: find.byType(Container),
          ),
        )
        .map((container) => container.decoration)
        .whereType<BoxDecoration>()
        .first;
    expect(card.boxShadow, isNotEmpty);
    // Тень рисуется под всей карточкой: сквозь полупрозрачную подложку она
    // затемняла бы саму карточку.
    expect(card.color!.a, 1);
  });

  testWidgets('«Открыть главу» ведёт во вкладку Библии на этот стих', (
    tester,
  ) async {
    final container = await pump(tester);

    await tester.tap(find.byTooltip('Открыть главу'));

    final request = container.read(bibleOpenRequestProvider);
    expect(request?.book, 'Ps');
    expect(request?.chapter, 22);
    expect(request?.verse, 1);
    expect(request?.source, BibleOpenSource.verseOfDay);
  });

  testWidgets('стих сохраняется в копилку той же закладкой, что в Библии', (
    tester,
  ) async {
    final container = await pump(tester);

    await tester.tap(find.byIcon(CupertinoIcons.bookmark));
    await tester.pump();

    final saved = container.read(bookmarksProvider).value!;
    expect(saved.single.id, 'bible-Ps-22:1');
    expect(saved.single.text, _verse.text);
    expect(saved.single.source, 'Псалтирь 22:1');
  });

  testWidgets('пока стих грузится, место под карточку уже занято', (
    tester,
  ) async {
    final pending = Completer<DailyVerse>();
    await pump(tester, load: () => pending.future);

    expect(find.text('Стих дня'), findsOneWidget);
    expect(find.text('Загружаем стих'), findsOneWidget);
  });

  testWidgets('без сети и кэша карточка не показывается', (tester) async {
    await pump(
      tester,
      load: () async =>
          throw const AppFailure('Нет сети', kind: FailureKind.network),
    );
    await tester.pump();

    expect(find.text('Стих дня'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
