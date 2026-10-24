import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_share_button.dart';
import '../../../../core/widgets/reading_overflow_listener.dart';
import '../../../bookmarks/domain/entities/bookmark.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../../daily_cards/domain/entities/day_card.dart';
import '../../../daily_cards/presentation/screens/full_card_text_screen.dart';
import '../../../daily_cards/presentation/widgets/reader_progress_rail.dart';
import '../../../daily_cards/presentation/widgets/vertical_card_reader.dart';
import '../../../reading/domain/entities/daily_reading.dart';
import '../../../reading/presentation/widgets/interpretation_sheet.dart';
import '../../../reading/presentation/widgets/verse_view.dart';
import '../../domain/entities/bible_book.dart';
import '../../domain/entities/bible_chapter.dart';
import '../../domain/entities/bible_reading_position.dart';
import '../providers/providers.dart';
import 'bible_screen.dart';

enum BibleReadingSessionMode { main, viewer }

class BibleReaderScreen extends ConsumerStatefulWidget {
  const BibleReaderScreen({
    required this.sessionMode,
    required this.book,
    required this.chapter,
    this.initialVerse = 1,
    this.onClose,
    this.showClose = true,
    this.openSource = BibleOpenSource.tab,
    super.key,
  });

  final BibleReadingSessionMode sessionMode;

  /// Откуда открыта глава: аналитика отличает первый вход, каталог,
  /// чтение дня и закладку.
  final BibleOpenSource openSource;

  final BibleBook book;
  final int chapter;
  final VoidCallback? onClose;

  /// Во вкладке Библии читалка корневая: закрывать её некуда.
  final bool showClose;

  /// Сохранённый стих открывается в контексте всей главы, без обрезки начала.
  final int initialVerse;

  @override
  ConsumerState<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

typedef _ReadingVerse = ({
  BibleBook book,
  int chapter,
  BibleVerse verse,
  String? interpretationAuthor,
});

class _BibleReaderScreenState extends ConsumerState<BibleReaderScreen> {
  final _fullTextNeeded = <String, bool>{};

  late BibleBook _book = widget.book;
  late int _chapter = widget.chapter;
  late int _initialVerse = widget.initialVerse;
  late BibleOpenSource _openSource = widget.openSource;
  PageController? _controller;
  final _verses = <_ReadingVerse>[];
  int _page = 0;
  BibleBook? _lastBook;
  int? _lastChapter;
  Object? _initialError;
  Object? _nextError;
  int _loadRevision = 0;
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
    // Поздний ответ предыдущей главы не должен менять новый выбор.
    final revision = ++_loadRevision;
    setState(() {
      _loadingInitial = true;
      _initialError = null;
    });
    try {
      final chapter = await ref.read(
        bibleChapterProvider((_book.code, _chapter)).future,
      );
      if (!mounted || revision != _loadRevision) return;
      final startIndex = chapter.verses.indexWhere(
        (verse) => verse.number == _initialVerse,
      );
      _controller?.dispose();
      setState(() {
        // Ищем номер стиха, а не индекс: в тексте могут быть пропуски номеров.
        _page = math.max(0, startIndex);
        _controller = PageController(initialPage: _page);
        _verses.addAll([
          for (final verse in chapter.verses)
            (
              book: _book,
              chapter: _chapter,
              verse: verse,
              interpretationAuthor: chapter.interpretationAuthor,
            ),
        ]);
        _lastBook = _book;
        _lastChapter = _chapter;
        _loadingInitial = false;
      });
      _logOpened(_book, _chapter, _openSource);
      ref.read(bibleChapterStatusesProvider.notifier).refresh();
      _saveReadingPosition(_page);
    } on Object catch (error) {
      if (!mounted || revision != _loadRevision) return;
      _logLoadFailed(error);
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
    final revision = _loadRevision;
    setState(() {
      _loadingNext = true;
      _nextError = null;
    });
    try {
      final chapter = await ref.read(
        bibleChapterProvider((target.$1.code, target.$2)).future,
      );
      if (!mounted || revision != _loadRevision) return;
      setState(() {
        _verses.addAll([
          for (final verse in chapter.verses)
            (
              book: target.$1,
              chapter: target.$2,
              verse: verse,
              interpretationAuthor: chapter.interpretationAuthor,
            ),
        ]);
        _lastBook = target.$1;
        _lastChapter = target.$2;
        _loadingNext = false;
      });
      _logOpened(target.$1, target.$2, BibleOpenSource.next);
      ref.read(bibleChapterStatusesProvider.notifier).refresh();
      _saveReadingPosition(_page);
    } on Object catch (error) {
      if (!mounted || revision != _loadRevision) return;
      _logLoadFailed(error);
      setState(() {
        _loadingNext = false;
        _nextError = error;
      });
    }
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
    _saveReadingPosition(page);
    // Скачиваем следующую главу только после явного свайпа за последний стих.
    if (page == _verses.length && !_loadingNext && _nextError == null) {
      _loadNext();
    }
  }

  void _saveReadingPosition(int page) {
    if (page < 0 || page >= _verses.length) return;
    final position = _verses[page];
    var first = page;
    while (first > 0 && _sameChapter(_verses[first - 1], position)) {
      first--;
    }
    var last = page;
    while (last + 1 < _verses.length &&
        _sameChapter(_verses[last + 1], position)) {
      last++;
    }
    ref.read(bibleChapterStatusesProvider.notifier).saveProgress(
      position.book.code,
      position.chapter,
      (
        verse: position.verse.number,
        fraction: (page - first + 1) / (last - first + 1),
      ),
    );
    if (widget.sessionMode == BibleReadingSessionMode.main) {
      ref.read(saveBibleReadingPositionProvider)(
        BibleReadingPosition(
          book: position.book.code,
          chapter: position.chapter,
          verse: position.verse.number,
        ),
      );
    }
    _markChapterReadIfFinished(page);
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
        .read(analyticsProvider)
        .log(
          AnalyticsEvent.bibleChapterCompleted(
            book: verse.book.code,
            chapter: verse.chapter,
          ),
        );
    ref
        .read(bibleChapterStatusesProvider.notifier)
        .markRead(verse.book.code, verse.chapter);
  }

  void _logLoadFailed(Object error) => ref
      .read(analyticsProvider)
      .log(
        AnalyticsEvent.contentLoadFailed(
          content: LoadedContent.bibleChapter,
          kind: failureKindOf(error),
        ),
      );

  void _logRetry() => ref
      .read(analyticsProvider)
      .log(AnalyticsEvent.contentRetryTapped(LoadedContent.bibleChapter));

  void _logOpened(BibleBook book, int chapter, BibleOpenSource source) => ref
      .read(analyticsProvider)
      .log(
        AnalyticsEvent.bibleChapterOpened(
          book: book.code,
          chapter: chapter,
          source: source,
        ),
      );

  Future<void> _selectChapter() async {
    final target = await Navigator.of(context).push<(BibleBook, int, int)>(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: BibleScreen(selectChapter: true)),
      ),
    );
    if (!mounted || target == null) return;
    _book = target.$1;
    _chapter = target.$2;
    _initialVerse = target.$3;
    _openSource = BibleOpenSource.catalog;
    _verses.clear();
    _lastBook = null;
    _lastChapter = null;
    _nextError = null;
    _loadingNext = false;
    await _loadInitial();
  }

  Widget _closeAction(AppColorsExtension colors) => IconButton(
    tooltip: 'Закрыть',
    onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
    constraints: const BoxConstraints.tightFor(width: 48, height: 48),
    padding: EdgeInsets.zero,
    icon: Icon(CupertinoIcons.xmark, color: colors.homeSubtitle, size: 22),
  );

  Widget _catalogAction(AppColorsExtension colors) => IconButton(
    tooltip: 'Книги и главы',
    onPressed: _selectChapter,
    icon: Icon(
      CupertinoIcons.list_bullet,
      color: colors.homeSubtitle,
      size: 22,
    ),
  );

  /// Во вкладке выбор книги стоит справа сверху и сразу показывает,
  /// какая книга и глава открыты.
  Widget _bookPicker(
    AppColorsExtension colors,
    BibleBook book,
    int chapter, {
    double top = 4,
  }) => Padding(
    padding: EdgeInsets.only(top: top, right: 12),
    child: Tooltip(
      message: 'Книги и главы',
      child: Material(
        color: colors.ink.withValues(alpha: 0.06),
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _selectChapter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  // Капсула не должна растягиваться на всю ширину экрана.
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$chapter',
                  style: TextStyle(fontSize: 15, color: colors.textSecondary),
                ),
                const SizedBox(width: 4),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 14,
                  color: colors.homeSubtitle,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    if (_loadingInitial) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 48,
          automaticallyImplyLeading: false,
          leading: _hasCatalogAction ? _catalogAction(colors) : null,
          actions: [
            if (widget.showClose)
              _closeAction(colors)
            else
              _bookPicker(colors, _book, _chapter, top: 0),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_initialError != null) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 48,
          automaticallyImplyLeading: false,
          leading: _hasCatalogAction ? _catalogAction(colors) : null,
          title: Text(_book.title),
          actions: [
            if (widget.showClose)
              _closeAction(colors)
            else
              _bookPicker(colors, _book, _chapter, top: 0),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Не удалось открыть чтение'),
              TextButton(
                onPressed: () {
                  _logRetry();
                  ref.invalidate(bibleChapterProvider((_book.code, _chapter)));
                  _loadInitial();
                },
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
                        _logRetry();
                        ref.invalidate(
                          bibleChapterProvider((target.$1.code, target.$2)),
                        );
                        _loadNext();
                      },
                      child: const Text('Повторить загрузку главы'),
                    ),
            );
          }
          final item = _verses[index];
          final itemCard = _cardFor(item);
          final verse = _verseOf(item);
          return ReadingOverflowListener(
            key: ValueKey(itemCard.id),
            onChanged: (needed) {
              if (_fullTextNeeded[itemCard.id] == needed) return;
              setState(() => _fullTextNeeded[itemCard.id] = needed);
            },
            // Тот же вид стиха, что в чтении дня: толкование открывается
            // кнопкой под стихом, к которому написано.
            child: VerseView(
              verse: verse,
              bookAbbreviation: item.book.abbreviation,
              shareContent: SharedContent.bibleVerse,
              onOpenInterpretation: verse.hasInterpretation
                  ? () => InterpretationSheet.show(
                      context,
                      verse: verse,
                      author: item.interpretationAuthor,
                    )
                  : null,
            ),
          );
        },
        // Во вкладке название книги показывает капсула выбора справа.
        header: widget.showClose
            ? Text(
                position.book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              )
            : const SizedBox.shrink(),
        leftRail: _chapterProgress(position, colors),
        actions: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_fullTextNeeded[card.id] ?? false)
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
              content: SharedContent.bibleVerse,
              iconSize: 28,
              buttonSize: 56,
            ),
          ],
        ),
        onClose: widget.onClose ?? () => Navigator.of(context).pop(),
        showExit: false,
        topLeftAction: _hasCatalogAction
            ? _catalogAction(colors)
            : const SizedBox.shrink(),
        topRightAction: widget.showClose
            ? _closeAction(colors)
            : _bookPicker(colors, position.book, position.chapter),
        closeColor: colors.homeSubtitle,
      ),
    );
  }

  bool get _hasCatalogAction =>
      widget.showClose && widget.sessionMode == BibleReadingSessionMode.main;

  DayCard _cardFor(_ReadingVerse position) => DayCard(
    id: 'bible-${position.book.code}-${position.chapter}:${position.verse.number}',
    type: CardType.reading,
    body: position.verse.text,
    source: '${position.chapter}:${position.verse.number}',
  );

  Verse _verseOf(_ReadingVerse position) => Verse(
    number: position.verse.number,
    chapter: position.chapter,
    text: position.verse.text,
    interpretation: position.verse.interpretation,
    interpretationRange: position.verse.interpretationRange,
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
    return ReaderProgressRail(
      key: ValueKey('${position.book.code}-${position.chapter}'),
      count: count,
      currentIndex: current,
      accent: colors.accent,
      // Точки показывают стихи текущей главы, а они идут подряд.
      onSelect: (index) => _controller!.jumpToPage(first + index),
    );
  }

  bool _sameChapter(_ReadingVerse a, _ReadingVerse b) =>
      a.book.code == b.book.code && a.chapter == b.chapter;
}
