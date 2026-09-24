import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_link_button.dart';
import '../../../../core/widgets/brand_loading_view.dart';
import '../../../daily_cards/domain/entities/day_card.dart';
import '../../../daily_cards/presentation/screens/card_viewer_screen.dart';
import '../../domain/entities/daily_reading.dart';
import '../providers/providers.dart';
import '../widgets/interpretation_sheet.dart';
import '../widgets/verse_view.dart';

/// Загружает чтение дня и передаёт его стихи общему просмотрщику карточек.
/// У этого маршрута нет своего визуального устройства: отдельный стих — одна
/// страница [CardViewerScreen], как и у остальных материалов дня.
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
        pageBuilder: (context, index) {
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
