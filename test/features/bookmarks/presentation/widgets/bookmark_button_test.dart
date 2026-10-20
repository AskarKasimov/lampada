import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/analytics_provider.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/bookmarks/domain/entities/bookmark.dart';
import 'package:lampada/features/bookmarks/domain/repositories/bookmarks_repository.dart';
import 'package:lampada/features/bookmarks/presentation/providers/providers.dart';
import 'package:lampada/features/bookmarks/presentation/widgets/bookmark_button.dart';

import '../../../../support/fake_analytics.dart';

class _MemoryBookmarks implements BookmarksRepository {
  var items = <Bookmark>[];

  @override
  Future<Result<List<Bookmark>>> load() async => Success(items);

  @override
  Future<Result<List<Bookmark>>> remove(String id) async {
    items = items.where((b) => b.id != id).toList();
    return Success(items);
  }

  @override
  Future<Result<List<Bookmark>>> save(Bookmark bookmark) async {
    items = [bookmark, ...items];
    return Success(items);
  }
}

void main() {
  final quote = Bookmark(
    id: 'quote-2026-10-20',
    kind: BookmarkKind.card,
    text: 'Мысль',
    source: 'Святой',
    label: 'Цитата дня',
    savedAt: DateTime(2026),
  );

  testWidgets('сохранение и удаление уходят в аналитику с типом', (
    tester,
  ) async {
    final analytics = FakeAnalytics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookmarksRepositoryProvider.overrideWithValue(_MemoryBookmarks()),
          analyticsProvider.overrideWithValue(analytics),
        ],
        child: MaterialApp(
          home: Scaffold(body: BookmarkButton(bookmark: quote)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BookmarkButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BookmarkButton));
    await tester.pumpAndSettle();

    expect(analytics.single('bookmark_added'), {
      'kind': 'card',
      'content': 'quote',
    });
    expect(analytics.single('bookmark_removed'), {
      'kind': 'card',
      'placement': 'reader',
    });
  });
}
