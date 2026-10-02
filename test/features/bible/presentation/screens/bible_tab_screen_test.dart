import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/bible/domain/bible_chapter_statuses.dart';
import 'package:lampada/features/bible/domain/entities/bible_chapter.dart';
import 'package:lampada/features/bible/domain/repositories/bible_repository.dart';
import 'package:lampada/features/bible/presentation/providers/providers.dart';
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

void main() {
  for (final fail in [false, true]) {
    testWidgets(
      'Библию можно закрыть при ${fail ? "ошибке" : "загрузке"} позиции',
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
            child: MaterialApp(
              home: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (routeContext) => BibleTabScreen(
                        onClose: () => Navigator.of(routeContext).pop(),
                      ),
                    ),
                  ),
                  child: const Text('Открыть Библию'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Открыть Библию'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        if (fail) {
          expect(find.text('Повторить загрузку места чтения'), findsOneWidget);
        }
        final close = find.byTooltip('Закрыть');
        expect(close, findsOneWidget);
        expect(tester.getCenter(close).dx, greaterThan(400));
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(find.byType(BibleTabScreen), findsNothing);
        expect(find.text('Открыть Библию'), findsOneWidget);
      },
    );
  }
}
