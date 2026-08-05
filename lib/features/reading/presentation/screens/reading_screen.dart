import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_link_button.dart';
import '../../../../core/widgets/brand_loading_view.dart';
import '../../../bookmarks/domain/entities/bookmark.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../domain/entities/daily_reading.dart';
import '../providers/providers.dart';
import '../widgets/interpretation_sheet.dart';
import '../widgets/reading_progress_line.dart';
import '../widgets/verse_view.dart';

/// Ридер чтения дня: один стих на экран, свайп к следующему, в конце
/// отрывка — карточка толкования (FR-007…009).
///
/// Отдельный маршрут поверх шелла, а не вкладка: чтение — единственное место
/// в приложении, где юзер уходит в длинную последовательность, и таб-бар под
/// ней только мешал бы.
class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({
    super.key,
    required this.reference,
    this.onFinished,
  });

  /// Машинная ссылка отрывка из карточки дня: `Jn.10:1-9`.
  final String reference;

  /// Зовётся, когда юзер дочитал до конца и закрыл ридер.
  final VoidCallback? onFinished;

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close({required bool finished}) {
    if (finished) widget.onFinished?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dailyReadingProvider(widget.reference));
    final colors = AppColorsExtension.of(context);

    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const BrandLoadingView(),
          error: (e, _) => _ErrorView(
            kind: switch (e) {
              AppFailure(kind: final k) => k,
              _ => FailureKind.unknown,
            },
            onRetry: () =>
                ref.invalidate(dailyReadingProvider(widget.reference)),
            onClose: () => _close(finished: false),
          ),
          data: (reading) => _reader(reading, colors),
        ),
      ),
    );
  }

  /// Закладка на текущий стих.
  /// savedAt — заглушка, момент сохранения ставит сама кнопка.
  Bookmark _bookmarkForPage(DailyReading reading) {
    final verse = reading.verses[_page.clamp(0, reading.verses.length - 1)];
    return Bookmark(
      id: 'verse-${widget.reference}-${verse.chapter}:${verse.number}',
      kind: BookmarkKind.verse,
      text: verse.text,
      source: '${reading.label.split('.').first}.'
          '${verse.chapter}:${verse.number}',
      label: 'Стих',
      savedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Widget _reader(DailyReading reading, AppColorsExtension colors) {
    final total = reading.pageCount;
    final isLast = _page >= total - 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
          child: Row(
            children: [
              Text(
                reading.label,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.3,
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              BookmarkButton(bookmark: _bookmarkForPage(reading)),
              AppLinkButton(
                label: isLast ? 'Готово' : 'Закрыть',
                color: isLast ? colors.link : colors.homeSubtitle,
                fontSize: 12,
                onPressed: () => _close(finished: isLast),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ReadingProgressLine(position: _page, total: total),
        ),
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: total,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) {
              final verse = reading.verses[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 34, vertical: 24),
                child: Center(
                  child: VerseView(
                    verse: verse,
                    // Толкование есть не у каждого стиха: у Феофилакта
                    // покрыты не все, и обещать кнопкой пустоту незачем.
                    onOpenInterpretation: verse.hasInterpretation
                        ? () => InterpretationSheet.show(
                              context,
                              verse: verse,
                              author: reading.interpretationAuthor,
                            )
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
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
    // Тот же принцип, что на «Сегодня»: советовать чинить Wi-Fi, когда лёг
    // сам источник, — отправлять юзера чинить исправное.
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
