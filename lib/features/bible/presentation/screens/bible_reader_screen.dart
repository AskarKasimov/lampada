import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_share_button.dart';
import '../../../bookmarks/domain/entities/bookmark.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../../daily_cards/domain/entities/day_card.dart';
import '../../../daily_cards/presentation/screens/full_card_text_screen.dart';
import '../../../daily_cards/presentation/widgets/card_content.dart';
import '../../../daily_cards/presentation/widgets/progress_dots.dart';
import '../../../daily_cards/presentation/widgets/vertical_card_reader.dart';
import '../../domain/entities/bible_book.dart';
import '../../domain/entities/bible_chapter.dart';
import '../providers/providers.dart';

class BibleReaderScreen extends ConsumerStatefulWidget {
  const BibleReaderScreen({required this.book, super.key});

  final BibleBook book;

  @override
  ConsumerState<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

typedef _ReadingVerse = ({BibleBook book, int chapter, BibleVerse verse});

class _BibleReaderScreenState extends ConsumerState<BibleReaderScreen> {
  final _controller = PageController();
  final _verses = <_ReadingVerse>[];
  int _page = 0;
  BibleBook? _lastBook;
  int? _lastChapter;
  Object? _initialError;
  Object? _nextError;
  bool _loadingInitial = true;
  bool _loadingNext = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadInitial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loadingInitial = true;
      _initialError = null;
    });
    try {
      final chapter = await ref.read(
        bibleChapterProvider((widget.book.code, 1)).future,
      );
      if (!mounted) return;
      setState(() {
        _verses.addAll([
          for (final verse in chapter.verses)
            (book: widget.book, chapter: 1, verse: verse),
        ]);
        _lastBook = widget.book;
        _lastChapter = 1;
        _loadingInitial = false;
      });
      _loadNext();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingInitial = false;
        _initialError = error;
      });
    }
  }

  (BibleBook, int)? get _nextTarget {
    final book = _lastBook;
    final chapter = _lastChapter;
    if (book == null || chapter == null) return null;
    if (chapter < book.chapterCount) return (book, chapter + 1);
    final index = bibleBooks.indexWhere((item) => item.code == book.code);
    if (index < 0 || index + 1 == bibleBooks.length) return null;
    return (bibleBooks[index + 1], 1);
  }

  Future<void> _loadNext() async {
    final target = _nextTarget;
    if (target == null || _loadingNext) return;
    setState(() {
      _loadingNext = true;
      _nextError = null;
    });
    try {
      final chapter = await ref.read(
        bibleChapterProvider((target.$1.code, target.$2)).future,
      );
      if (!mounted) return;
      setState(() {
        _verses.addAll([
          for (final verse in chapter.verses)
            (book: target.$1, chapter: target.$2, verse: verse),
        ]);
        _lastBook = target.$1;
        _lastChapter = target.$2;
        _loadingNext = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingNext = false;
        _nextError = error;
      });
    }
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
    // Предзагружаем следующую главу у конца уже полученных стихов.
    if (page >= _verses.length - 3 && !_loadingNext && _nextError == null) {
      _loadNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    if (_loadingInitial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_initialError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.book.title)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Не удалось открыть чтение'),
              TextButton(
                onPressed: _loadInitial,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    final position = _verses[_page.clamp(0, _verses.length - 1)];
    final source =
        '${position.book.title} ${position.chapter}:${position.verse.number}';
    final card = _cardFor(position);
    final bookmark = Bookmark(
      id: card.id,
      kind: BookmarkKind.verse,
      text: position.verse.text,
      source: source,
      label: 'Стих',
      savedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

    return Scaffold(
      body: VerticalCardReader(
        controller: _controller,
        itemCount: _verses.length + (_nextTarget == null ? 0 : 1),
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          if (index == _verses.length) {
            return Center(
              child: _nextError == null
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: () {
                        final target = _nextTarget;
                        if (target == null) return;
                        ref.invalidate(
                          bibleChapterProvider((target.$1.code, target.$2)),
                        );
                        _loadNext();
                      },
                      child: const Text('Повторить загрузку главы'),
                    ),
            );
          }
          final itemCard = _cardFor(_verses[index]);
          return CardContent(
            key: ValueKey(itemCard.id),
            card: itemCard,
            showBadge: false,
            showSourceDash: false,
            scrollable: false,
          );
        },
        header: Text(
          position.book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        leftRail: _chapterProgress(position, colors),
        actions: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (CardContent.needsFullText(card))
              ReaderActionButton(
                tooltip: 'Открыть полный текст',
                onPressed: () => Navigator.of(
                  context,
                ).push(FullCardTextRoute(card: card, showSourceDash: false)),
                icon: Icons.aspect_ratio_outlined,
                color: colors.homeSubtitle,
              ),
            BookmarkButton(bookmark: bookmark, iconSize: 28, buttonSize: 56),
            AppShareButton(
              text: '${bookmark.text}\n\n— $source',
              iconSize: 28,
              buttonSize: 56,
            ),
          ],
        ),
        onClose: () => Navigator.of(context).pop(),
        closeColor: colors.homeSubtitle,
      ),
    );
  }

  DayCard _cardFor(_ReadingVerse position) => DayCard(
    id: 'bible-${position.book.code}-${position.chapter}:${position.verse.number}',
    type: CardType.reading,
    body: position.verse.text,
    source: '${position.chapter}:${position.verse.number}',
  );

  Widget _chapterProgress(_ReadingVerse position, AppColorsExtension colors) {
    final page = _page.clamp(0, _verses.length - 1);
    var first = page;
    while (first > 0 && _sameChapter(_verses[first - 1], position)) {
      first--;
    }
    var last = page;
    while (last + 1 < _verses.length &&
        _sameChapter(_verses[last + 1], position)) {
      last++;
    }
    final count = last - first + 1;
    final current = page - first;
    const visibleCount = 12;
    final windowStart = (current - visibleCount ~/ 2).clamp(
      0,
      (count - visibleCount).clamp(0, count),
    );
    final windowLength = (count - windowStart).clamp(0, visibleCount);

    // В Псалтири встречаются очень длинные главы: показываем окно точек,
    // чтобы индикатор не выходил за пределы экрана.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (windowStart > 0)
          Text('⋮', style: TextStyle(color: colors.textSecondary)),
        ProgressDots(
          count: windowLength,
          currentIndex: current - windowStart,
          axis: Axis.vertical,
          accentColors: List.filled(windowLength, colors.accent),
        ),
        if (windowStart + windowLength < count)
          Text('⋮', style: TextStyle(color: colors.textSecondary)),
      ],
    );
  }

  bool _sameChapter(_ReadingVerse a, _ReadingVerse b) =>
      a.book.code == b.book.code && a.chapter == b.chapter;
}
