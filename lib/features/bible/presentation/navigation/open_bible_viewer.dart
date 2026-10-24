import 'package:flutter/material.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/navigation/bottom_up_modal_route.dart';
import '../../domain/entities/bible_book.dart';
import '../screens/bible_reader_screen.dart';

final Expando<bool> _viewerOpening = Expando<bool>();

/// Открывает временное чтение по ссылке внутри текущей вкладки.
Future<void> openBibleViewer(
  BuildContext context, {
  required BibleBook book,
  required int chapter,
  required int verse,
  required BibleOpenSource source,
  bool nextChapterOnMissingVerse = false,
}) async {
  final navigator = Navigator.of(context, rootNavigator: false);
  if (_viewerOpening[navigator] == true) return;
  _viewerOpening[navigator] = true;
  try {
    await navigator.push<void>(
      BottomUpModalRoute<void>(
        builder: (_) => BibleReaderScreen(
          sessionMode: BibleReadingSessionMode.viewer,
          book: book,
          chapter: chapter,
          initialVerse: verse,
          nextChapterOnMissingVerse: nextChapterOnMissingVerse,
          openSource: source,
        ),
      ),
    );
  } finally {
    _viewerOpening[navigator] = false;
  }
}
