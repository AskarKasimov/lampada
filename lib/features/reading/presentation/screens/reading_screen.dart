import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_link_button.dart';
import '../../../../core/widgets/brand_loading_view.dart';
import '../../../bible/domain/entities/bible_book.dart';
import '../../../bible/presentation/screens/bible_reader_screen.dart';
import '../../../daily_cards/domain/entities/day_card.dart';
import '../../../daily_cards/presentation/screens/card_viewer_screen.dart';
import '../../domain/entities/daily_reading.dart';
import '../providers/providers.dart';
import '../widgets/interpretation_sheet.dart';
import '../widgets/verse_view.dart';

/// Загружает чтение дня и передаёт его стихи общему просмотрщику карточек.
/// После дневных стихов предлагает открыть полную главу с первого стиха.
class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({
    required this.reference,
    required this.date,
    required this.recordProgress,
    required this.recordRead,
    super.key,
  });

  final String reference;
  final DateTime date;
  final bool recordProgress;
  final bool recordRead;

  BibleBook? get _book => bibleBooks
      .where((book) => book.code == reference.trim().split('.').first)
      .firstOrNull;

  List<int> _chaptersFor(DailyReading reading) => reading.verses
      .map((verse) => verse.chapter)
      .where((chapter) => chapter > 0 && chapter <= (_book?.chapterCount ?? 0))
      .toSet()
      .toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyReadingProvider(reference));
    return async.when(
      loading: () => const Scaffold(body: BrandLoadingView()),
      error: (e, _) => Scaffold(
        body: SafeArea(
          child: _ErrorView(
            kind: switch (e) {
              AppFailure(kind: final k) => k,
              _ => FailureKind.unknown,
            },
            onRetry: () => ref.invalidate(dailyReadingProvider(reference)),
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      data: (reading) => CardViewerScreen(
        cards: _cardsFor(reading),
        startIndex: 0,
        date: date,
        recordProgress: recordProgress,
        recordRead: recordRead,
        actionsBuilder: (context, index) =>
            index == reading.verses.length ? const SizedBox.shrink() : null,
        pageBuilder: (context, index) {
          if (index == reading.verses.length) {
            final chapters = _chaptersFor(reading);
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
        },
      ),
    );
  }

  List<DayCard> _cardsFor(DailyReading reading) => [
    for (final verse in reading.verses)
      DayCard(
        id: 'verse-$reference-${verse.chapter}:${verse.number}',
        type: CardType.reading,
        body: verse.text,
        source:
            '${reading.label.split('.').first}.${verse.chapter}:${verse.number}',
      ),
    if (_chaptersFor(reading).isNotEmpty)
      DayCard(
        id: 'reading-chapters-$reference',
        type: CardType.reading,
        body: 'Прочитать главу полностью',
        source: reading.label,
      ),
  ];
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.kind,
    required this.onRetry,
    required this.onClose,
  });

  final FailureKind kind;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final title = kind == FailureKind.network
        ? 'Нет подключения к интернету'
        : 'Чтение сейчас недоступно';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.ink),
            ),
            const SizedBox(height: 6),
            Text(
              'Карточки дня остаются с вами',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.homeSubtitle),
            ),
            const SizedBox(height: 12),
            AppLinkButton(
              label: 'Повторить',
              color: colors.link,
              fontSize: 12,
              onPressed: onRetry,
            ),
            AppLinkButton(
              label: 'Вернуться к карточкам',
              color: colors.homeSubtitle,
              fontSize: 12,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
