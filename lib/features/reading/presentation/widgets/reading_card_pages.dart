import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../bible/domain/entities/bible_book.dart';
import '../../../bible/presentation/providers/providers.dart';
import '../../../daily_cards/domain/entities/day_card.dart';
import '../../domain/entities/daily_reading.dart';
import 'interpretation_sheet.dart';
import 'verse_view.dart';

/// Подпись ссылки и переход по ней.
typedef ReadingLink = ({String label, VoidCallback onPressed});

/// Страницы одного евангельского отрывка для отдельного и общего просмотрщика.
class ReadingCardPages {
  const ReadingCardPages({
    required this.reference,
    required this.reading,
    this.offerChapters = true,
  });

  final String reference;
  final DailyReading reading;

  /// Завершать ли стихи страницей с предложением прочитать главу. «Мудрость
  /// дня» её выключает и показывает [chapterLinks] на экране завершения.
  final bool offerChapters;

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
    if (offerChapters && _chapters.isNotEmpty)
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
        bookAbbreviation: _book?.abbreviation,
        onOpenInterpretation: verse.hasInterpretation
            ? () => InterpretationSheet.show(
                context,
                verse: verse,
                author: reading.interpretationAuthor,
              )
            : null,
      );
    }

    final links = chapterLinks(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            links.length == 1
                ? 'Хотите прочесть главу полностью?'
                : 'Хотите прочесть главы полностью?',
            textAlign: TextAlign.center,
            style: AppTheme.headingStyle(context, fontSize: 22),
          ),
          const SizedBox(height: 18),
          for (final link in links)
            TextButton(onPressed: link.onPressed, child: Text(link.label)),
        ],
      ),
    );
  }

  /// Предлагает чтение главы или продолжение после дневного отрывка.
  ///
  /// Глава открывается во вкладке «Библия», а не отдельным окном: там её
  /// можно дочитать и листать дальше, место чтения сохраняется.
  List<ReadingLink> chapterLinks(
    BuildContext context, {
    bool continueAfterDailyReading = false,
  }) {
    final chapters = _chapters;
    final book = _book;
    if (book == null) return const [];
    if (continueAfterDailyReading) {
      final lastVerse = reading.verses.lastOrNull;
      if (lastVerse == null || !chapters.contains(lastVerse.chapter)) {
        return const [];
      }
      final nextVerse = lastVerse.number + 1;
      return [
        (
          label:
              'Продолжить с ${book.abbreviation}. '
              '${lastVerse.chapter}:$nextVerse',
          onPressed: () => ProviderScope.containerOf(context, listen: false)
              .read(bibleOpenRequestProvider.notifier)
              .open(book.code, lastVerse.chapter, verse: nextVerse),
        ),
      ];
    }
    return [
      for (final chapter in chapters)
        (
          label: chapters.length == 1
              ? 'Прочитать главу полностью'
              : 'Прочитать главу $chapter',
          onPressed: () => ProviderScope.containerOf(context, listen: false)
              .read(bibleOpenRequestProvider.notifier)
              .open(book.code, chapter, verse: 1),
        ),
    ];
  }
}
