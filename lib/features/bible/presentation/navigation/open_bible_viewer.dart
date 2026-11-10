import 'package:flutter/material.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/navigation/bottom_up_modal_route.dart';
import '../../../shell/presentation/services/after_reading_prompts.dart';
import '../../domain/entities/bible_book.dart';
import '../screens/bible_reader_screen.dart';

final Expando<bool> _viewerOpening = Expando<bool>();

/// Открывает временное чтение по ссылке внутри текущей вкладки.
///
/// [askAfterClose] — после закрытия задать запросы первого чтения
/// (напоминания, оценка). Выключают, когда просмотр лежит поверх другого
/// раздела, который задаст их сам при своём закрытии.
Future<void> openBibleViewer(
  BuildContext context, {
  required BibleBook book,
  required int chapter,
  required int verse,
  required BibleOpenSource source,
  bool nextChapterOnMissingVerse = false,
  bool askAfterClose = true,
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
  if (askAfterClose && context.mounted) {
    await askAfterReading(context, ReminderPromptTrigger.bible);
  }
}
