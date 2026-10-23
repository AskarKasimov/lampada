import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/analytics_event.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/bible/domain/bible_chapter_statuses.dart';
import 'package:lampada/features/bible/domain/entities/bible_chapter.dart';
import 'package:lampada/features/bible/domain/repositories/bible_repository.dart';
import 'package:lampada/features/bible/presentation/providers/providers.dart';
import 'package:lampada/features/bible/presentation/screens/bible_reader_screen.dart';
import 'package:lampada/features/bible/presentation/screens/bible_tab_screen.dart';

class _PendingStatusesRepository implements BibleRepository {
  final statuses = Completer<Result<BibleChapterStatuses>>();

  @override
  Future<Result<BibleChapterStatuses>> getChapterStatuses() => statuses.future;

  @override
  Future<Result<BibleChapter>> getChapter(String book, int chapter) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> markChapterRead(String book, int chapter) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> saveChapterProgress(
    String book,
    int chapter,
    BibleChapterProgress progress,
  ) => throw UnimplementedError();
}

/// Чистая установка: места чтения нет, главы грузятся бесконечно.
class _FreshInstallRepository extends _PendingStatusesRepository {
  _FreshInstallRepository() {
    statuses.complete(
      const Success((
        lastChapter: null,
        cached: <BibleChapterId>{},
        read: <BibleChapterId>{},
        progress: <BibleChapterId, BibleChapterProgress>{},
      )),
    );
  }

  @override
  Future<Result<BibleChapter>> getChapter(String book, int chapter) =>
      Completer<Result<BibleChapter>>().future;
}

void main() {
  testWidgets('первый вход открывает Евангелие от Иоанна с первой главы', (
    tester,
  ) async {
    // «В начале было Слово» понятнее новичку, чем родословие у Матфея.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(_FreshInstallRepository()),
        ],
        child: const MaterialApp(home: BibleTabScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    final reader = tester.widget<BibleReaderScreen>(
      find.byType(BibleReaderScreen),
    );
    expect(reader.book.code, 'Jn');
    expect(reader.chapter, 1);
  });

  testWidgets('запрос из «Стиха дня» открывает главу на этом стихе', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        bibleRepositoryProvider.overrideWithValue(_FreshInstallRepository()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BibleTabScreen()),
      ),
    );
    await tester.pump();

    container
        .read(bibleOpenRequestProvider.notifier)
        .open('Ps', 22, verse: 3, source: BibleOpenSource.verseOfDay);
    await tester.pump();
    await tester.pump();

    final reader = tester.widget<BibleReaderScreen>(
      find.byType(BibleReaderScreen),
    );
    expect(reader.book.code, 'Ps');
    expect(reader.chapter, 22);
    expect(reader.initialVerse, 3);
    expect(reader.openSource, BibleOpenSource.verseOfDay);
  });

  for (final fail in [false, true]) {
    testWidgets(
      'вкладка Библии без кнопки закрытия при ${fail ? "ошибке" : "загрузке"} позиции',
      (tester) async {
        final repository = _PendingStatusesRepository();
        if (fail) {
          repository.statuses.complete(
            const Failure(
              AppFailure('Ошибка хранилища', kind: FailureKind.unknown),
            ),
          );
        }
        await tester.pumpWidget(
          ProviderScope(
            overrides: [bibleRepositoryProvider.overrideWithValue(repository)],
            child: const MaterialApp(home: BibleTabScreen()),
          ),
        );
        await tester.pump();
        if (fail) {
          expect(find.text('Повторить загрузку места чтения'), findsOneWidget);
        } else {
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        }
        expect(find.byTooltip('Закрыть'), findsNothing);
      },
    );
  }
}
