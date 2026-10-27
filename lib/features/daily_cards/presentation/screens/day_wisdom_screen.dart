import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_on_show.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/format/date_key.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../reading/domain/entities/daily_reading.dart';
import '../../../reading/presentation/providers/providers.dart';
import '../../../reading/presentation/widgets/reading_card_pages.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/split_day_card_text.dart';
import '../providers/providers.dart';
import '../widgets/card_content.dart';
import '../widgets/day_wisdom_complete_view.dart';
import 'card_viewer_screen.dart';

/// Цитата, совет, притча и стихи Евангелия в одной вертикальной листалке.
/// Завершает её экран итога дня: только он засчитывает день в «Лампадку»,
/// чтение отдельных карточек серию не продлевает.
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
    // Даже при повторе загрузки сначала собираем весь набор страниц,
    // затем показываем точки с окончательным количеством карточек.
    if (readingAsync?.isLoading ?? false) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 48,
          automaticallyImplyLeading: false,
          actions: [_closeButton(context)],
        ),
        body: const _ReadingStatus(isLoading: true, onRetry: null),
      );
    }
    final reading = readingAsync?.value;
    final readingPages = reading != null && reading.verses.isNotEmpty
        ? ReadingCardPages(
            reference: reference!,
            reading: reading,
            offerChapters: false,
          )
        : null;
    // Длинная цитата, совет или притча делятся на страницы, чтобы реже
    // приходилось открывать полный текст.
    final ordinaryPages = [for (final card in ordinary) ..._pagesOf(card)];
    final contentCards = [
      for (final page in ordinaryPages) page.page,
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
    if (contentCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 48,
          automaticallyImplyLeading: false,
          actions: [_closeButton(context)],
        ),
        body: const Center(child: Text('За этот день карточек нет')),
      );
    }
    final completeIndex = contentCards.length;
    final viewerCards = [
      ...contentCards,
      // Тип нужен только точке прогресса: она продолжает цвет последней
      // карточки, а не притворяется ещё одним материалом.
      DayCard(
        id: 'day-complete',
        type: contentCards.last.type,
        body: '',
        source: '',
      ),
    ];

    // Экземпляр берём сейчас: при закрытии ref этого виджета уже недоступен.
    final analytics = ref.read(analyticsProvider);
    final requestedStart = _viewerStart(
      startIndex,
      ordinary,
      ordinaryPages,
      contentCards.length,
    );
    final savedPosition = switch (ref.read(loadDayWisdomPositionProvider)(
      date,
    )) {
      Success(value: final page) => page,
      Failure() => null,
    };
    final viewerStart = (savedPosition ?? requestedStart).clamp(
      0,
      contentCards.length - 1,
    );
    return CardViewerScreen(
      cards: viewerCards,
      onExit: (furthest) => analytics.log(
        AnalyticsEvent.wisdomClosed(
          dayOffset: dayOffset(date),
          pagesSeen: math.min(furthest + 1, completeIndex),
          pagesTotal: completeIndex,
          completed: furthest >= completeIndex,
        ),
      ),
      // Итог зажигает лампаду: до него доходят чтением, а не по точкам.
      lastScrubbablePage: completeIndex - 1,
      startIndex: viewerStart,
      date: date,
      // Карточки отмечаются прочитанными, но день зажигает только
      // экран завершения, см. DayWisdomCompleteView.countsDay.
      recordProgress: false,
      recordRead: recordRead,
      onPageChanged: (page) {
        // Итог не является страницей чтения и не должен сохранять позицию.
        if (page < completeIndex) {
          unawaited(ref.read(saveDayWisdomPositionProvider)(date, page));
        }
      },
      canMarkRead: (index) =>
          index < ordinaryPages.length ||
          (readingPages != null &&
              index < completeIndex &&
              readingPages.isVerse(index - ordinaryPages.length)),
      wholeCardOf: (index) => index < ordinaryPages.length
          ? ordinaryPages[index].card
          : viewerCards[index],
      headerBuilder: (context, index) =>
          index == completeIndex ? const SizedBox.shrink() : null,
      pageBuilder: (context, index) {
        if (index == completeIndex) {
          return DayWisdomCompleteView(
            date: date,
            recordsCompletion: recordRead,
            countsDay: recordProgress,
            onDone: () => Navigator.of(context).pop(),
            // Просмотр лежит поверх дневной сессии и возвращает к её итогу.
            links: [
              for (final link
                  in readingPages?.chapterLinks(
                        context,
                        continueAfterDailyReading: true,
                      ) ??
                      const <ReadingLink>[])
                (label: link.label, onPressed: link.onPressed),
            ],
          );
        }
        if (index < ordinaryPages.length) {
          final page = ordinaryPages[index];
          return CardContent(
            key: ValueKey(page.page.id),
            card: page.page,
            showBadge: false,
            scrollable: false,
            // Источник подписывает весь текст, поэтому стоит в его конце.
            showSource: page.isLast,
          );
        }
        if (readingPages != null) {
          return readingPages.page(context, index - ordinaryPages.length);
        }
        final status = _ReadingStatus(
          isLoading: readingAsync?.isLoading ?? false,
          onRetry: reference == null
              ? null
              : () {
                  analytics.log(
                    AnalyticsEvent.contentRetryTapped(LoadedContent.gospel),
                  );
                  ref.invalidate(dailyReadingProvider(reference));
                },
        );
        if (readingAsync?.hasError != true) return status;
        return AnalyticsOnShow(
          event: AnalyticsEvent.contentLoadFailed(
            content: LoadedContent.gospel,
            kind: failureKindOf(readingAsync?.error),
          ),
          child: status,
        );
      },
      actionsBuilder: (context, index) {
        if (index < ordinaryPages.length) return null;
        if (index == completeIndex) return const SizedBox.shrink();
        if (readingPages != null) {
          return readingPages.actions(context, index - ordinaryPages.length);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

IconButton _closeButton(BuildContext context) => IconButton(
  tooltip: 'Закрыть',
  onPressed: () => Navigator.of(context).pop(),
  constraints: const BoxConstraints.tightFor(width: 48, height: 48),
  padding: EdgeInsets.zero,
  icon: Icon(
    CupertinoIcons.xmark,
    size: 22,
    color: AppColorsExtension.of(context).homeSubtitle,
  ),
);

typedef _CardPage = ({DayCard page, DayCard card, bool isLast});

/// Страницы одной карточки. Короткая карточка остаётся собой, чтобы её
/// id и прогресс не менялись.
List<_CardPage> _pagesOf(DayCard card) {
  final chunks = splitDayCardText(card.body);
  if (chunks.length == 1) return [(page: card, card: card, isLast: true)];
  return [
    for (var i = 0; i < chunks.length; i++)
      (
        page: card.copyWith(id: '${card.id}#${i + 1}', body: chunks[i]),
        card: card,
        isLast: i == chunks.length - 1,
      ),
  ];
}

/// [DayWisdomScreen.startIndex] указывает на карточку, а листалка считает
/// страницы: открываем первую страницу этой карточки.
int _viewerStart(
  int startIndex,
  List<DayCard> ordinary,
  List<_CardPage> pages,
  int contentCount,
) {
  if (startIndex < ordinary.length) {
    final id = ordinary[startIndex].id;
    final page = pages.indexWhere((page) => page.card.id == id);
    if (page >= 0) return page;
  }
  // Евангелие идёт после всех страниц обычных карточек.
  final reading = pages.length + startIndex - ordinary.length;
  return reading.clamp(0, contentCount - 1);
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
