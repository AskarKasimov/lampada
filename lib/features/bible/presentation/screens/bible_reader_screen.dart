import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
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
  const BibleReaderScreen({
    required this.book,
    required this.chapter,
    this.initialVerse = 1,
    super.key,
  });

  final BibleBook book;
  final int chapter;

  /// Сохранённый стих открывается в контексте всей главы, без обрезки начала.
  final int initialVerse;

  @override
  ConsumerState<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

typedef _ReadingVerse = ({BibleBook book, int chapter, BibleVerse verse});

class _BibleReaderScreenState extends ConsumerState<BibleReaderScreen> {
  PageController? _controller;
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
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loadingInitial = true;
      _initialError = null;
    });
    try {
      final chapter = await ref.read(
        bibleChapterProvider((widget.book.code, widget.chapter)).future,
      );
      if (!mounted) return;
      final startIndex = chapter.verses.indexWhere(
        (verse) => verse.number == widget.initialVerse,
      );
      _controller?.dispose();
      setState(() {
        // Ищем номер стиха, а не индекс: в тексте могут быть пропуски номеров.
        _page = math.max(0, startIndex);
        _controller = PageController(initialPage: _page);
        _verses.addAll([
          for (final verse in chapter.verses)
            (book: widget.book, chapter: widget.chapter, verse: verse),
        ]);
        _lastBook = widget.book;
        _lastChapter = widget.chapter;
        _loadingInitial = false;
      });
      ref.read(bibleChapterStatusesProvider.notifier).refresh();
      _markChapterReadIfFinished(_page);
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
      ref.read(bibleChapterStatusesProvider.notifier).refresh();
      _markChapterReadIfFinished(_page);
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
    _markChapterReadIfFinished(page);
    // Скачиваем следующую главу только после явного свайпа за последний стих.
    if (page == _verses.length && !_loadingNext && _nextError == null) {
      _loadNext();
    }
  }

  void _markChapterReadIfFinished(int page) {
    if (page < 0 || page >= _verses.length) return;
    final verse = _verses[page];
    // Каждая загрузка приносит главу целиком, поэтому последний в ней стих
    // можно узнать и до загрузки следующей главы.
    if (page + 1 < _verses.length && _sameChapter(verse, _verses[page + 1])) {
      return;
    }
    final id = (verse.book.code, verse.chapter);
    if (ref.read(bibleChapterStatusesProvider).value?.read.contains(id) ??
        false) {
      return;
    }
    ref
        .read(bibleChapterStatusesProvider.notifier)
        .markRead(verse.book.code, verse.chapter);
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
        controller: _controller!,
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
                icon: CupertinoIcons.fullscreen,
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
    return _ChapterProgressRail(
      key: ValueKey('${position.book.code}-${position.chapter}'),
      count: count,
      currentIndex: current,
      accent: colors.accent,
    );
  }

  bool _sameChapter(_ReadingVerse a, _ReadingVerse b) =>
      a.book.code == b.book.code && a.chapter == b.chapter;
}

/// Показывает все точки главы; длинная колонка прокручивается к текущей.
class _ChapterProgressRail extends StatefulWidget {
  const _ChapterProgressRail({
    required this.count,
    required this.currentIndex,
    required this.accent,
    super.key,
  });

  final int count;
  final int currentIndex;
  final Color accent;

  @override
  State<_ChapterProgressRail> createState() => _ChapterProgressRailState();
}

class _ChapterProgressRailState extends State<_ChapterProgressRail> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerCurrent());
  }

  @override
  void didUpdateWidget(covariant _ChapterProgressRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerCurrent());
    }
  }

  void _centerCurrent() {
    if (!mounted || !_controller.hasClients) return;
    const dotStep = 14.0;
    final position = _controller.position;
    final offset =
        (widget.currentIndex * dotStep -
                position.viewportDimension / 2 +
                dotStep / 2)
            .clamp(0.0, position.maxScrollExtent);
    _controller.animateTo(
      offset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      width: 8,
      height: math.min(widget.count * 14.0, constraints.maxHeight),
      child: SingleChildScrollView(
        controller: _controller,
        child: ProgressDots(
          count: widget.count,
          currentIndex: widget.currentIndex,
          axis: Axis.vertical,
          accentColors: List.filled(widget.count, widget.accent),
        ),
      ),
    ),
  );
}
