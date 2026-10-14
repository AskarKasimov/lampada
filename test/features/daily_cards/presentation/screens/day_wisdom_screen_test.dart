import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/core/widgets/app_share_button.dart';
import 'package:lampada/features/bible/domain/entities/bible_chapter.dart';
import 'package:lampada/features/bible/presentation/providers/providers.dart';
import 'package:lampada/features/bible/presentation/screens/bible_reader_screen.dart';
import 'package:lampada/features/bookmarks/presentation/widgets/bookmark_button.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/screens/card_viewer_screen.dart';
import 'package:lampada/features/daily_cards/presentation/screens/day_wisdom_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/progress_dots.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/streak_card.dart';
import 'package:lampada/features/reading/domain/entities/daily_reading.dart';
import 'package:lampada/features/reading/presentation/providers/providers.dart';
import 'package:lampada/features/reading/presentation/widgets/verse_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('единая листалка ведёт от притчи к первому стиху', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const cards = [
      DayCard(
        id: 'quote',
        type: CardType.quote,
        body: 'Цитата',
        source: 'Источник',
      ),
      DayCard(
        id: 'advice',
        type: CardType.advice,
        body: 'Совет',
        source: 'Источник',
      ),
      DayCard(
        id: 'parable',
        type: CardType.parable,
        body: 'Притча',
        source: 'Источник',
      ),
      DayCard(
        id: 'reading',
        type: CardType.reading,
        body: 'Ин.10:1',
        source: 'Источник',
        reference: 'Jn.10:1',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dailyReadingProvider.overrideWith(
            (ref, reference) async => const DailyReading(
              label: 'Ин.10:1',
              verses: [Verse(number: 1, chapter: 10, text: 'Первый стих')],
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: DayWisdomScreen(
            cards: cards,
            startIndex: 2,
            date: DateTime(2026, 9, 29),
            recordProgress: false,
            recordRead: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Притча'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.byType(VerseView), findsOneWidget);
    expect(find.text('Первый стих'), findsOneWidget);
  });

  testWidgets('загрузка не засчитывает Евангелие до первого стиха', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final pending = Completer<DailyReading>();
    final date = DateTime.now();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dailyReadingProvider.overrideWith((ref, reference) => pending.future),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: DayWisdomScreen(
            cards: const [
              DayCard(
                id: 'reading',
                type: CardType.reading,
                body: 'Ин.10:1',
                source: 'Источник',
                reference: 'Jn.10:1',
              ),
            ],
            startIndex: 0,
            date: date,
            recordProgress: false,
            recordRead: true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Загружаем Евангелие дня'), findsOneWidget);
    expect(find.byType(CardViewerScreen), findsNothing);
    expect(find.byType(ProgressDots), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DayWisdomScreen)),
    );
    expect(
      (await container.read(
        dayProgressProvider.future,
      )).isReadOn(date, CardType.reading),
      isFalse,
    );

    pending.complete(
      const DailyReading(
        label: 'Ин.10:1',
        verses: [Verse(number: 1, chapter: 10, text: 'Загруженный стих')],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Загруженный стих'), findsOneWidget);
    expect(
      (await container.read(
        dayProgressProvider.future,
      )).isReadOn(date, CardType.reading),
      isTrue,
    );
  });

  testWidgets('ошибка Евангелия оставляет цитату и позволяет повторить', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var attempts = 0;
    final date = DateTime.now();
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dailyReadingProvider.overrideWith((ref, reference) async {
            attempts++;
            if (attempts == 1) throw StateError('сеть недоступна');
            return const DailyReading(
              label: 'Ин.10:1',
              verses: [
                Verse(number: 1, chapter: 10, text: 'Стих после повтора'),
              ],
            );
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: DayWisdomScreen(
            cards: const [
              DayCard(
                id: 'quote',
                type: CardType.quote,
                body: 'Доступная цитата',
                source: 'Источник',
              ),
              DayCard(
                id: 'reading',
                type: CardType.reading,
                body: 'Ин.10:1',
                source: 'Источник',
                reference: 'Jn.10:1',
              ),
            ],
            startIndex: 1,
            date: date,
            recordProgress: false,
            recordRead: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DayWisdomScreen)),
    );
    expect(find.text('Евангелие дня сейчас недоступно'), findsOneWidget);
    expect(
      (await container.read(
        dayProgressProvider.future,
      )).isReadOn(date, CardType.reading),
      isFalse,
    );
    await tester.drag(find.byType(PageView), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('Доступная цитата'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('Стих после повтора'), findsOneWidget);
  });

  testWidgets('пустой отрывок не засчитывается прочитанным', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final date = DateTime.now();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dailyReadingProvider.overrideWith(
            (ref, reference) async =>
                const DailyReading(label: 'Ин.10:1', verses: []),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: DayWisdomScreen(
            cards: const [
              DayCard(
                id: 'reading',
                type: CardType.reading,
                body: 'Ин.10:1',
                source: 'Источник',
                reference: 'Jn.10:1',
              ),
            ],
            startIndex: 0,
            date: date,
            recordProgress: false,
            recordRead: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Евангелие дня сейчас недоступно'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DayWisdomScreen)),
    );
    expect(
      (await container.read(
        dayProgressProvider.future,
      )).isReadOn(date, CardType.reading),
      isFalse,
    );
  });

  group('экран завершения', () {
    const quote = DayCard(
      id: 'quote',
      type: CardType.quote,
      body: 'Цитата',
      source: 'Источник',
    );
    const reading = DayCard(
      id: 'reading',
      type: CardType.reading,
      body: 'Ин.10:1',
      source: 'Источник',
      reference: 'Jn.10:1',
    );

    Future<ProviderContainer> open(
      WidgetTester tester, {
      required DateTime date,
      required bool recordProgress,
      List<DayCard> cards = const [quote, reading],
      bool reduceMotion = true,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            dailyReadingProvider.overrideWith(
              (ref, reference) async => const DailyReading(
                label: 'Ин.10:1',
                verses: [Verse(number: 1, chapter: 10, text: 'Стих дня')],
              ),
            ),
            bibleChapterProvider.overrideWith(
              (ref, key) async => BibleChapter(
                book: key.$1,
                number: key.$2,
                verses: [BibleVerse(number: 1, text: '${key.$1} ${key.$2}:1')],
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            // Огонёк серии пульсирует бесконечно; без анимаций
            // pumpAndSettle дожидается конца перехода.
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: reduceMotion),
              child: child!,
            ),
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DayWisdomScreen(
                      cards: cards,
                      startIndex: 0,
                      date: date,
                      recordProgress: recordProgress,
                      recordRead: true,
                    ),
                  ),
                ),
                child: const Text('Открыть'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(DayWisdomScreen)),
      );
    }

    Future<void> next(WidgetTester tester) async {
      await tester.drag(find.byType(PageView), const Offset(0, -600));
      await tester.pumpAndSettle();
    }

    testWidgets('лампадку зажигает только экран завершения', (tester) async {
      final today = DateTime.now();
      final container = await open(tester, date: today, recordProgress: true);
      Future<bool> lit() async =>
          (await container.read(dayProgressProvider.future)).isLit(today);

      expect(find.text('Цитата'), findsOneWidget);
      expect(await lit(), isFalse);
      await next(tester);
      expect(find.text('Стих дня'), findsOneWidget);
      final progress = await container.read(dayProgressProvider.future);
      expect(progress.isReadOn(today, CardType.quote), isTrue);
      expect(progress.isReadOn(today, CardType.reading), isTrue);
      expect(await lit(), isFalse);

      await next(tester);
      expect(find.text('Слава Богу!'), findsOneWidget);
      expect(await lit(), isTrue);
      final streak = find.byType(StreakCard);
      expect(
        find.descendant(of: streak, matching: find.text('1')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: streak, matching: find.text('день подряд')),
        findsOneWidget,
      );
    });

    testWidgets('предложение главы стоит под основной кнопкой', (tester) async {
      await open(tester, date: DateTime.now(), recordProgress: true);
      await next(tester);
      await next(tester);

      expect(find.text('Хотите прочесть главу полностью?'), findsNothing);
      final done = find.text('Готово');
      final chapter = find.text('Прочитать главу полностью');
      expect(done, findsOneWidget);
      expect(chapter, findsOneWidget);
      expect(
        tester.getTopLeft(chapter).dy,
        greaterThan(tester.getBottomLeft(done).dy),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(DayWisdomScreen)),
      );
      await tester.tap(chapter);
      await tester.pumpAndSettle();
      // Глава открывается во вкладке «Библия», а не отдельным окном поверх.
      expect(find.byType(BibleReaderScreen), findsNothing);
      expect(find.byType(DayWisdomScreen), findsNothing);
      final request = container.read(bibleOpenRequestProvider);
      expect((request?.book, request?.chapter), ('Jn', 10));
    });

    testWidgets('повторное завершение сразу ведёт к полной главе', (
      tester,
    ) async {
      final today = DateTime.now();
      final container = await open(tester, date: today, recordProgress: true);
      await next(tester);
      await next(tester);
      expect(find.text('Слава Богу!'), findsOneWidget);
      expect(
        (await container.read(
          dayProgressProvider.future,
        )).isWisdomCompletedOn(today),
        isTrue,
      );
      expect(container.read(bibleOpenRequestProvider), isNull);
      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();
      await next(tester);
      await next(tester);

      expect(find.byType(DayWisdomScreen), findsNothing);
      final request = container.read(bibleOpenRequestProvider);
      expect((request?.book, request?.chapter), ('Jn', 10));
    });

    testWidgets('без главы повторное завершение просто показывает итог', (
      tester,
    ) async {
      await open(
        tester,
        date: DateTime.now(),
        recordProgress: true,
        cards: const [quote],
      );
      await next(tester);
      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();
      await next(tester);

      expect(find.text('Слава Богу!'), findsOneWidget);
    });

    testWidgets('«Готово» закрывает «Мудрость дня»', (tester) async {
      await open(tester, date: DateTime.now(), recordProgress: true);
      await next(tester);
      await next(tester);

      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();

      expect(find.byType(DayWisdomScreen), findsNothing);
      expect(find.text('Открыть'), findsOneWidget);
    });

    testWidgets('без Евангелия завершение идёт сразу после карточек', (
      tester,
    ) async {
      await open(
        tester,
        date: DateTime.now(),
        recordProgress: true,
        cards: const [quote],
      );
      await next(tester);

      expect(find.text('Слава Богу!'), findsOneWidget);
      expect(find.text('Прочитать главу полностью'), findsNothing);
    });

    testWidgets('лампада загорается после появления экрана, с отдачей', (
      tester,
    ) async {
      final haptics = <String?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String?);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await open(
        tester,
        date: DateTime.now(),
        recordProgress: true,
        reduceMotion: false,
      );
      await next(tester);
      // Экран завершения: огонёк серии пульсирует бесконечно, поэтому
      // дальше только pump с явной длительностью.
      await tester.drag(find.byType(PageView), const Offset(0, -600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final streak = find.byType(StreakCard);
      expect(find.text('Слава Богу!'), findsOneWidget);
      expect(
        find.descendant(of: streak, matching: find.text('0')),
        findsOneWidget,
        reason: 'до кульминации серия ещё прежняя',
      );
      expect(haptics, isNotEmpty, reason: 'появление печати даёт отдачу');
      final beforeLighting = haptics.length;
      const weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
      final todayLabel = find.descendant(
        of: streak,
        matching: find.text(weekdays[DateTime.now().weekday - 1]),
      );
      expect(
        todayLabel,
        findsNothing,
        reason: 'неделя появляется только после того, как лампада загорится',
      );

      // Кульминация: лампада загорается, число перекатывается.
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.descendant(of: streak, matching: find.text('1')),
        findsOneWidget,
      );
      expect(haptics.length, greaterThan(beforeLighting));
      expect(todayLabel, findsNothing, reason: 'лампада ещё разгорается');
      expect(
        find.text('Готово').hitTestable(),
        findsNothing,
        reason: 'кнопки появляются вместе с неделей',
      );

      // Лампада разгорелась, следом раскрывается неделя.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.descendant(of: streak, matching: find.text('0')),
        findsNothing,
      );
      expect(todayLabel, findsOneWidget);
      expect(find.text('Готово').hitTestable(), findsOneWidget);
      expect(
        find.text('Прочитать главу полностью').hitTestable(),
        findsOneWidget,
      );
    });

    testWidgets('при уменьшении движения итог виден сразу', (tester) async {
      await open(tester, date: DateTime.now(), recordProgress: true);
      await next(tester);
      await next(tester);

      final streak = find.byType(StreakCard);
      expect(
        find.descendant(of: streak, matching: find.text('1')),
        findsOneWidget,
      );
    });

    testWidgets('прошлый день завершается без серии и не зажигается', (
      tester,
    ) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final container = await open(
        tester,
        date: yesterday,
        recordProgress: false,
      );
      await next(tester);
      await next(tester);

      expect(find.text('Слава Богу!'), findsOneWidget);
      expect(find.byType(StreakCard), findsNothing);
      final progress = await container.read(dayProgressProvider.future);
      expect(progress.visitedDays, isNot(contains(dateKey(yesterday))));
    });
  });

  group('длинные карточки', () {
    const question =
        'Как правильно совершать паломничество в святое место, чтобы '
        'получить от поездки духовную пользу?';
    final answer = [
      'Во время паломничества надо иметь постоянно в виду главную цель: '
          'молитву и покаяние, а не туристические впечатления.',
      'Стоит заранее узнать о святыне, подготовиться к исповеди и '
          'причастию, взять с собой записки о здравии и упокоении.',
    ].join(' ');
    final advice = DayCard(
      id: 'advice',
      type: CardType.advice,
      body: '$question $answer',
      source: 'Азбука веры',
    );
    const parable = DayCard(
      id: 'parable',
      type: CardType.parable,
      body: 'Короткая притча.',
      source: 'Притчи',
    );

    Future<void> open(WidgetTester tester, {int startIndex = 0}) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: DayWisdomScreen(
              cards: [advice, parable],
              startIndex: startIndex,
              date: DateTime.now(),
              recordProgress: false,
              recordRead: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('совет делится на вопрос и ответ, подпись в конце', (
      tester,
    ) async {
      await open(tester);

      expect(find.text(question), findsOneWidget);
      expect(find.text('— Азбука веры'), findsNothing);
      final dots = tester.widget<ProgressDots>(find.byType(ProgressDots));
      // Вопрос, ответ, притча и экран итога.
      expect(dots.count, 4);

      await tester.drag(find.byType(PageView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.text(answer), findsOneWidget);
      expect(find.text('— Азбука веры'), findsOneWidget);
    });

    testWidgets('закладка и отправка на странице берут весь текст', (
      tester,
    ) async {
      await open(tester);

      final bookmark = tester.widget<BookmarkButton>(
        find.byType(BookmarkButton),
      );
      expect(bookmark.bookmark.id, 'advice');
      expect(bookmark.bookmark.text, advice.body);
      final share = tester.widget<AppShareButton>(find.byType(AppShareButton));
      expect(share.text, contains(advice.body));
    });

    testWidgets('открывается с первой страницы нужной карточки', (
      tester,
    ) async {
      await open(tester, startIndex: 1);

      expect(find.text('Короткая притча.'), findsOneWidget);
    });
  });
}
