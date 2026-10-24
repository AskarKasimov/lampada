import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/analytics_provider.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/bible/domain/bible_chapter_statuses.dart';
import 'package:lampada/features/bible/domain/entities/bible_book.dart';
import 'package:lampada/features/bible/domain/entities/bible_chapter.dart';
import 'package:lampada/features/bible/domain/entities/bible_reading_position.dart';
import 'package:lampada/features/bible/domain/repositories/bible_repository.dart';
import 'package:lampada/features/bible/presentation/providers/providers.dart';
import 'package:lampada/features/bible/presentation/screens/bible_reader_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/rail_scrubber.dart';
import 'package:lampada/features/reading/presentation/widgets/verse_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/fake_analytics.dart';
import '../../../../support/haptics.dart';

class _RecordingRepository implements BibleRepository {
  final positions = <BibleReadingPosition>[];
  final progress = <BibleChapterId, BibleChapterProgress>{};

  @override
  Future<Result<BibleChapter>> getChapter(String book, int chapter) =>
      throw UnimplementedError();

  @override
  Future<Result<BibleChapterStatuses>> getChapterStatuses() async => Success((
    lastChapter: null,
    cached: <BibleChapterId>{},
    read: <BibleChapterId>{},
    progress: {...progress},
  ));

  @override
  Future<Result<BibleReadingPosition?>> getReadingPosition() async =>
      const Success(null);

  @override
  Future<Result<void>> markChapterRead(String book, int chapter) async =>
      const Success(null);

  @override
  Future<Result<void>> saveChapterProgress(
    String book,
    int chapter,
    BibleChapterProgress value,
  ) async {
    progress[(book, chapter)] = value;
    return const Success(null);
  }

  @override
  Future<Result<void>> saveReadingPosition(
    BibleReadingPosition position,
  ) async {
    positions.add(position);
    return const Success(null);
  }
}

void main() {
  late SharedPreferences prefs;
  late FakeAnalytics analytics;
  late _RecordingRepository repository;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    analytics = FakeAnalytics();
    repository = _RecordingRepository();
  });

  Future<void> open(
    WidgetTester tester, {
    required int verse,
    BibleReadingSessionMode mode = BibleReadingSessionMode.viewer,
    bool showClose = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          analyticsProvider.overrideWithValue(analytics),
          bibleRepositoryProvider.overrideWithValue(repository),
          bibleChapterProvider.overrideWith(
            (ref, key) async => const BibleChapter(
              book: 'Gen',
              number: 1,
              verses: [
                BibleVerse(number: 1, text: 'В начале'),
                BibleVerse(
                  number: 2,
                  text: 'Земля же была безвидна',
                  interpretation: 'Объяснение второго стиха',
                  interpretationRange: 'Быт.1:2',
                ),
              ],
              interpretationAuthor: 'Толковая Библия А.П. Лопухина',
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: BibleReaderScreen(
            sessionMode: mode,
            book: bibleBooks.first,
            chapter: 1,
            initialVerse: verse,
            showClose: showClose,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('стих без толкования не обещает его кнопкой', (tester) async {
    await open(tester, verse: 1);

    expect(find.text('В начале').hitTestable(), findsOneWidget);
    expect(find.byType(VerseInterpretationButton), findsNothing);
  });

  testWidgets('в просмотре нет каталога, крестик остаётся справа', (
    tester,
  ) async {
    await open(tester, verse: 1, showClose: true);

    expect(find.byTooltip('Книги и главы'), findsNothing);
    expect(find.byTooltip('Закрыть'), findsOneWidget);
  });

  testWidgets(
    'крестик просмотра остаётся в одном слоте при загрузке и контенте',
    (tester) async {
      final pending = Completer<BibleChapter>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            bibleRepositoryProvider.overrideWithValue(repository),
            bibleChapterProvider.overrideWith((ref, key) => pending.future),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (_) => BibleReaderScreen(
                        sessionMode: BibleReadingSessionMode.viewer,
                        book: bibleBooks.first,
                        chapter: 1,
                        showClose: true,
                      ),
                    ),
                  ),
                  child: const Text('Источник Библии'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Источник Библии'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final close = find.byTooltip('Закрыть');
      expect(close, findsOneWidget);
      expect(find.byTooltip('Книги и главы'), findsNothing);
      final loadingY = tester.getCenter(close).dy;
      expect(
        tester.getCenter(find.byIcon(CupertinoIcons.xmark)).dx,
        greaterThan(tester.getSize(find.byType(Scaffold).last).width / 2),
      );

      pending.complete(
        const BibleChapter(
          book: 'Gen',
          number: 1,
          verses: [BibleVerse(number: 1, text: 'В начале')],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('В начале'), findsOneWidget);
      expect(
        tester.getCenter(find.byTooltip('Закрыть')).dy,
        closeTo(loadingY, 0.5),
      );
    },
  );

  testWidgets('ошибка просмотра сохраняет правый крестик без каталога', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          bibleRepositoryProvider.overrideWithValue(repository),
          bibleChapterProvider.overrideWith((ref, key) async {
            throw Exception('offline');
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: BibleReaderScreen(
            sessionMode: BibleReadingSessionMode.viewer,
            book: bibleBooks.first,
            chapter: 1,
            showClose: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final close = find.byTooltip('Закрыть');
    expect(find.text('Не удалось открыть чтение'), findsOneWidget);
    expect(close, findsOneWidget);
    expect(find.byTooltip('Книги и главы'), findsNothing);
    expect(find.byIcon(CupertinoIcons.arrow_left), findsNothing);
    expect(
      tester.getCenter(close).dx,
      greaterThan(tester.getSize(find.byType(Scaffold)).width / 2),
    );
  });

  testWidgets('только основное чтение сохраняет личное место', (tester) async {
    await open(tester, verse: 2);
    expect(repository.positions, isEmpty);
    expect(repository.progress[('Gen', 1)]?.verse, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    await open(tester, verse: 2, mode: BibleReadingSessionMode.main);

    expect(repository.positions, [
      const BibleReadingPosition(book: 'Gen', chapter: 1, verse: 2),
    ]);
  });

  testWidgets('толкование открывается со стиха главы, как в чтении дня', (
    tester,
  ) async {
    await open(tester, verse: 2);

    await tester.tap(find.byType(VerseInterpretationButton));
    await tester.pumpAndSettle();

    expect(find.text('Объяснение второго стиха'), findsOneWidget);
    expect(find.text('на Быт.1:2'), findsOneWidget);
    expect(find.text('— Толковая Библия А.П. Лопухина'), findsOneWidget);
    expect(analytics.names, contains('interpretation_opened'));
  });

  testWidgets('под стихом сокращение книги, глава и стих', (tester) async {
    await open(tester, verse: 1);

    expect(find.text('Быт. 1:1').hitTestable(), findsOneWidget);
    expect(find.text('1:1'), findsNothing);
  });

  testWidgets('по столбику точек стихи листаются пальцем со щелчком', (
    tester,
  ) async {
    final haptics = recordHaptics(tester);
    await open(tester, verse: 1);

    final rail = tester.getRect(find.byType(RailScrubber));
    await tester.tapAt(rail.bottomCenter - const Offset(0, 1));
    await tester.pumpAndSettle();

    expect(find.text('Земля же была безвидна').hitTestable(), findsOneWidget);
    expect(find.text('Быт. 1:2').hitTestable(), findsOneWidget);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
  });
}
