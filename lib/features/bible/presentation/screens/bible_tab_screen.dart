import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/bible_book.dart';
import '../../domain/entities/bible_reading_position.dart';
import '../providers/providers.dart';
import 'bible_reader_screen.dart';

/// Вход во вкладку восстанавливает независимую позицию основного чтения.
///
/// Это корень вкладки, а не модальный экран: кнопки «Закрыть» нет,
/// уходят отсюда через навбар.

/// Книга, с которой вкладка открывается на чистой установке.
const _firstBook = 'Jn';

class BibleTabScreen extends ConsumerStatefulWidget {
  const BibleTabScreen({super.key});

  @override
  ConsumerState<BibleTabScreen> createState() => _BibleTabScreenState();
}

class _BibleTabScreenState extends ConsumerState<BibleTabScreen> {
  late Future<BibleReadingPosition?> _position = _loadPosition();

  Future<BibleReadingPosition?> _loadPosition() async {
    final result = await ref.read(loadBibleReadingPositionProvider)();
    return switch (result) {
      Success(value: final position) => position,
      Failure(failure: final failure) => throw failure,
    };
  }

  Widget _statusScreen(Widget body) => Scaffold(body: Center(child: body));

  @override
  Widget build(BuildContext context) => FutureBuilder<BibleReadingPosition?>(
    future: _position,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return _statusScreen(const CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _statusScreen(
          TextButton(
            onPressed: () => setState(() => _position = _loadPosition()),
            child: const Text('Повторить загрузку места чтения'),
          ),
        );
      }
      final position = snapshot.data;
      // Первый вход открывает Иоанна: «В начале было Слово» понятнее
      // новичку, чем родословие, с которого начинается Матфей.
      final book = bibleBooks.firstWhere(
        (book) => book.code == (position?.book ?? _firstBook),
        orElse: () => bibleBooks.firstWhere((book) => book.code == _firstBook),
      );
      return BibleReaderScreen(
        sessionMode: BibleReadingSessionMode.main,
        book: book,
        chapter: position?.chapter ?? 1,
        initialVerse: position?.verse ?? 1,
        showClose: false,
        openSource: position == null
            ? BibleOpenSource.firstOpen
            : BibleOpenSource.tab,
      );
    },
  );
}
