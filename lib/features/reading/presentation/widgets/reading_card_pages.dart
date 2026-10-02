import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../bible/domain/entities/bible_book.dart';
import '../../../bible/presentation/screens/bible_reader_screen.dart';
import '../../../daily_cards/domain/entities/day_card.dart';
import '../../domain/entities/daily_reading.dart';
import 'interpretation_sheet.dart';
import 'verse_view.dart';

/// Страницы одного евангельского отрывка для отдельного и общего просмотрщика.
class ReadingCardPages {
  const ReadingCardPages({required this.reference, required this.reading});

  final String reference;
  final DailyReading reading;

  BibleBook? get _book => bibleBooks
      .where((book) => book.code == reference.trim().split('.').first)
      .firstOrNull;

  List<int> get _chapters => reading.verses
      .map((verse) => verse.chapter)
      .where((chapter) => chapter > 0 && chapter <= (_book?.chapterCount ?? 0))
      .toSet()
      .toList();

  List<DayCard> get cards => [
    for (final verse in reading.verses)
      DayCard(
        id: 'verse-$reference-${verse.chapter}:${verse.number}',
        type: CardType.reading,
        body: verse.text,
        source:
            '${reading.label.split('.').first}.${verse.chapter}:${verse.number}',
      ),
    if (_chapters.isNotEmpty)
      DayCard(
        id: 'reading-chapters-$reference',
        type: CardType.reading,
        body: 'Прочитать главу полностью',
        source: reading.label,
      ),
  ];

  bool isVerse(int index) => index < reading.verses.length;

  Widget? actions(BuildContext context, int index) =>
      isVerse(index) ? null : const SizedBox.shrink();

  Widget page(BuildContext context, int index) {
    if (isVerse(index)) {
      final verse = reading.verses[index];
      return VerseView(
        verse: verse,
        onOpenInterpretation: verse.hasInterpretation
            ? () => InterpretationSheet.show(
                context,
                verse: verse,
                author: reading.interpretationAuthor,
              )
            : null,
      );
    }

    final chapters = _chapters;
    final colors = AppColorsExtension.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            chapters.length == 1
                ? 'Хотите прочесть главу полностью?'
                : 'Хотите прочесть главы полностью?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, color: colors.ink),
          ),
          const SizedBox(height: 18),
          for (final chapter in chapters)
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) =>
                      BibleReaderScreen(book: _book!, chapter: chapter),
                ),
              ),
              child: Text(
                chapters.length == 1
                    ? 'Прочитать главу полностью'
                    : 'Прочитать главу $chapter',
              ),
            ),
        ],
      ),
    );
  }
}
