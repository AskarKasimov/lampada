import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/format/date_key.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_share_button.dart';
import '../../../bookmarks/domain/entities/bookmark.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../domain/entities/bible_book.dart';
import '../../domain/entities/daily_verse.dart';
import '../providers/providers.dart';

/// «Стих дня» на главной. Пока стих грузится, карточка уже стоит на месте,
/// чтобы плитки под ней не прыгали. Без сети и без кэша главы карточки нет:
/// пустая рамка с ошибкой над дневными плитками только мешала бы.
class VerseOfDaySection extends ConsumerWidget {
  const VerseOfDaySection({required this.date, super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verse = ref.watch(verseOfDayProvider(dateKey(date)));
    if (verse.value case final verse?) return VerseOfDayCard(verse: verse);
    // Ошибку проверяем через hasError: при перезапросе состояние остаётся
    // загрузкой, но прежняя ошибка уже известна.
    if (verse.hasError) return const SizedBox.shrink();
    return const VerseOfDayCard();
  }
}

class VerseOfDayCard extends ConsumerWidget {
  const VerseOfDayCard({this.verse, super.key});

  /// null, пока стих загружается.
  final DailyVerse? verse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColorsExtension.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final verse = this.verse;
    final book = verse == null
        ? null
        : bibleBooks.where((book) => book.code == verse.book).firstOrNull;
    return Padding(
      padding:
          AppSpacing.of(context).horizontal +
          const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: verse == null || book == null
              ? null
              : () => ref
                    .read(bibleOpenRequestProvider.notifier)
                    .open(
                      verse.book,
                      verse.chapter,
                      verse: verse.verse,
                      source: BibleOpenSource.verseOfDay,
                    ),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
            decoration: BoxDecoration(
              // Нейтральная подложка: цветные плитки ниже остаются входами в
              // разделы, а стих читается прямо здесь. Она непрозрачная: тень
              // рисуется под всей карточкой и сквозь прозрачную подложку
              // затемнила бы её.
              color: Color.alphaBlend(
                colors.ink.withValues(alpha: isDark ? 0.07 : 0.045),
                colors.background,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.cardShadow(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название и ссылка набраны как названия и подписи
                      // плиток главной: на ней один набор заголовков.
                      Text('Стих дня', style: AppTheme.cardTitleStyle(context)),
                      if (verse != null && book != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          '${book.abbreviation}. ${verse.reference}',
                          style: AppTheme.cardCaptionStyle(context),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: Text(
                    verse?.text ?? 'Загружаем стих',
                    style: AppTheme.quoteStyle(context).copyWith(
                      fontSize: 20,
                      height: 1.4,
                      color: verse == null ? colors.homeSubtitle : colors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (verse != null && book != null)
                  _Actions(verse: verse, book: book)
                else
                  // Ряд кнопок резервируем и при загрузке: карточка не растёт.
                  const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.verse, required this.book});

  final DailyVerse verse;
  final BibleBook book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Подпись и id как у стиха в читалке Библии: сохранённый здесь стих
    // отмечен сохранённым и там, и наоборот.
    final source = '${book.title} ${verse.reference}';
    final bookmark = Bookmark(
      // Одиночный стих совпадает с закладкой этого стиха в читалке Библии;
      // у отрывка своя закладка.
      id:
          'bible-${verse.book}-${verse.chapter}:${verse.verse}'
          '${verse.endVerse == null ? '' : '-${verse.endVerse}'}',
      kind: BookmarkKind.verse,
      text: verse.text,
      source: source,
      label: 'Стих',
      savedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          BookmarkButton(bookmark: bookmark),
          AppShareButton(
            text: '${verse.text}\n\n— $source',
            content: SharedContent.bibleVerse,
          ),
        ],
      ),
    );
  }
}
