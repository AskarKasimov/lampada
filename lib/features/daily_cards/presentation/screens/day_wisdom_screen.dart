import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../reading/domain/entities/daily_reading.dart';
import '../../../reading/presentation/providers/providers.dart';
import '../../../reading/presentation/widgets/reading_card_pages.dart';
import '../../domain/entities/day_card.dart';
import '../widgets/card_content.dart';
import 'card_viewer_screen.dart';

/// Цитата, совет, притча и стихи Евангелия в одной вертикальной листалке.
class DayWisdomScreen extends ConsumerWidget {
  const DayWisdomScreen({
    required this.cards,
    required this.startIndex,
    required this.date,
    required this.recordProgress,
    required this.recordRead,
    super.key,
  });

  final List<DayCard> cards;
  final int startIndex;
  final DateTime date;
  final bool recordProgress;
  final bool recordRead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordinary = cards
        .where(
          (card) =>
              card.type != CardType.reading && card.type != CardType.basics,
        )
        .toList();
    final readingCard = cards
        .where((card) => card.type == CardType.reading)
        .firstOrNull;
    final reference = readingCard?.reference;
    final AsyncValue<DailyReading>? readingAsync = reference == null
        ? null
        : ref.watch(dailyReadingProvider(reference));
    final reading = readingAsync?.value;
    final readingPages = reading != null && reading.verses.isNotEmpty
        ? ReadingCardPages(reference: reference!, reading: reading)
        : null;
    final viewerCards = [
      ...ordinary,
      if (readingCard != null)
        if (readingPages != null)
          ...readingPages.cards
        else
          DayCard(
            id: 'reading-pending-${readingCard.id}',
            type: CardType.reading,
            body: readingCard.body,
            source: readingCard.source,
          ),
    ];
    if (viewerCards.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('За этот день карточек нет')),
      );
    }

    return CardViewerScreen(
      cards: viewerCards,
      startIndex: startIndex.clamp(0, viewerCards.length - 1),
      date: date,
      recordProgress: recordProgress,
      recordRead: recordRead,
      canMarkRead: (index) =>
          index < ordinary.length ||
          (readingPages != null &&
              readingPages.isVerse(index - ordinary.length)),
      pageBuilder: (context, index) {
        if (index < ordinary.length) {
          return CardContent(
            key: ValueKey(viewerCards[index].id),
            card: viewerCards[index],
            showBadge: false,
            scrollable: false,
          );
        }
        if (readingPages != null) {
          return readingPages.page(context, index - ordinary.length);
        }
        return _ReadingStatus(
          isLoading: readingAsync?.isLoading ?? false,
          onRetry: reference == null
              ? null
              : () => ref.invalidate(dailyReadingProvider(reference)),
        );
      },
      actionsBuilder: (context, index) {
        if (index < ordinary.length) return null;
        if (readingPages != null) {
          return readingPages.actions(context, index - ordinary.length);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ReadingStatus extends StatelessWidget {
  const _ReadingStatus({required this.isLoading, required this.onRetry});

  final bool isLoading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.of(context).horizontal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Загружаем Евангелие дня',
                style: TextStyle(color: colors.ink),
              ),
            ] else ...[
              Text(
                'Евангелие дня сейчас недоступно',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.ink),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: onRetry, child: const Text('Повторить')),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
