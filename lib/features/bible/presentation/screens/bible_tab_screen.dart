import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../domain/bible_chapter_statuses.dart';
import '../../domain/entities/bible_book.dart';
import '../providers/providers.dart';
import 'bible_reader_screen.dart';

/// Вход во вкладку восстанавливает последнее место, в том числе после перезапуска.
///
/// Это корень вкладки, а не модальный экран: кнопки «Закрыть» нет,
/// уходят отсюда через навбар.
class BibleTabScreen extends ConsumerStatefulWidget {
  const BibleTabScreen({super.key});

  @override
  ConsumerState<BibleTabScreen> createState() => _BibleTabScreenState();
}

class _BibleTabScreenState extends ConsumerState<BibleTabScreen> {
  late Future<BibleChapterStatuses> _statuses = _loadStatuses();

  Future<BibleChapterStatuses> _loadStatuses() async {
    final result = await ref.read(loadBibleChapterStatusesProvider)();
    return switch (result) {
      Success(value: final statuses) => statuses,
      Failure(failure: final failure) => throw failure,
    };
  }

  Widget _statusScreen(Widget body) => Scaffold(body: Center(child: body));

  @override
  Widget build(BuildContext context) => FutureBuilder<BibleChapterStatuses>(
    future: _statuses,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return _statusScreen(const CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _statusScreen(
          TextButton(
            onPressed: () => setState(() => _statuses = _loadStatuses()),
            child: const Text('Повторить загрузку места чтения'),
          ),
        );
      }
      final statuses = snapshot.data!;
      final id = statuses.lastChapter;
      final book = bibleBooks.firstWhere(
        (book) => book.code == (id?.$1 ?? 'Mt'),
        orElse: () => bibleBooks.firstWhere((book) => book.code == 'Mt'),
      );
      return BibleReaderScreen(
        book: book,
        chapter: id?.$2 ?? 1,
        initialVerse: statuses.progress[id]?.verse ?? 1,
        showClose: false,
      );
    },
  );
}
