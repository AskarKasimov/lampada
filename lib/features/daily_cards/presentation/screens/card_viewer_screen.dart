import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_pill_badge.dart';
import '../../../../core/widgets/app_share_button.dart';
import '../../../../core/widgets/reading_overflow_listener.dart';
import '../../../bookmarks/domain/entities/bookmark.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../domain/entities/day_card.dart';
import '../providers/providers.dart';
import '../theme/card_type_style.dart';
import '../widgets/card_content.dart';
import '../widgets/card_swipe_nudge.dart';
import '../widgets/progress_dots.dart';
import '../widgets/rail_scrubber.dart';
import '../widgets/vertical_card_reader.dart';
import 'full_card_text_screen.dart';

typedef CardPageBuilder = Widget Function(BuildContext context, int index);

/// Полноэкранный просмотр карточек дня — без таб-бара и вообще без хрома
/// вокруг: на экране остаётся одна мысль, как требует §6.
///
/// Отдельный маршрут поверх шелла, а не содержимое вкладки: только так
/// нижняя навигация не отъедает низ экрана у текста.
class CardViewerScreen extends ConsumerStatefulWidget {
  const CardViewerScreen({
    required this.cards,
    required this.startIndex,
    required this.date,
    required this.recordProgress,
    required this.recordRead,
    this.canMarkRead,
    this.pageBuilder,
    this.actionsBuilder,
    this.headerBuilder,
    this.wholeCardOf,
    this.onExit,
    this.onPageChanged,
    this.lastScrubbablePage,
    super.key,
  });

  /// Карточки-страницы. Евангелие может идти после цитаты, совета и притчи;
  /// курс открывается отдельно.
  final List<DayCard> cards;
  final int startIndex;
  final DateTime date;

  /// Засчитывать ли дату посещённой.
  final bool recordProgress;

  /// Записывать ли прочтение карточек. Для будущих дат выключено: их точки
  /// непрочитанного должны оставаться видимыми после предварительного чтения.
  final bool recordRead;

  /// Заглушка загрузки не считается прочитанным Евангелием.
  final bool Function(int index)? canMarkRead;

  /// Дальше этой страницы по точкам не долистать: за ней экран итога,
  /// который нужно заслужить чтением, а не прыжком. null: без ограничения.
  final int? lastScrubbablePage;

  /// Дополнительное содержимое страницы. Рамка, жесты, шапка и действия
  /// остаются общими для всех карточек; меняется только центральный материал.
  final CardPageBuilder? pageBuilder;

  /// Служебная страница может заменить действия закладки и отправки текста.
  /// null из builder оставляет стандартную панель текущей карточки.
  final Widget? Function(BuildContext context, int index)? actionsBuilder;

  /// Заменяет плашку типа над карточкой. null из builder оставляет плашку.
  final Widget? Function(BuildContext context, int index)? headerBuilder;

  /// Карточка целиком для закладки и отправки. Страница длинного текста —
  /// только его часть, а сохранять и делиться нужно всем текстом.
  final DayCard Function(int index)? wholeCardOf;

  /// Вызывается при закрытии с самым дальним показанным индексом: по нему
  /// аналитика видит, на какой карточке бросают чтение.
  final void Function(int furthestIndex)? onExit;

  /// Вызывается при показе страницы, включая исходную при открытии.
  final ValueChanged<int>? onPageChanged;

  @override
  ConsumerState<CardViewerScreen> createState() => _CardViewerScreenState();
}

class _CardViewerScreenState extends ConsumerState<CardViewerScreen> {
  final _fullTextNeeded = <String, bool>{};

  late final PageController _controller = PageController(
    initialPage: widget.startIndex,
  );
  late int _index = widget.startIndex;
  late int _furthest = widget.startIndex;
  String? _markedCardId;
  var _swipeNudgeHasStarted = false;

  int get _pageCount => widget.cards.length;

  @override
  void initState() {
    super.initState();
    _markCurrentAsRead(widget.startIndex);
    widget.onPageChanged?.call(widget.startIndex);
  }

  @override
  void dispose() {
    widget.onExit?.call(_furthest);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CardViewerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index < widget.cards.length &&
        (_index >= oldWidget.cards.length ||
            oldWidget.cards[_index].id != widget.cards[_index].id)) {
      _markCurrentAsRead(_index);
    }
  }

  /// Засчитывает карточку прочитанной сразу при показе, не дожидаясь
  /// «Дальше» — иначе, закрыв просмотрщик раньше конца, юзер оставил бы
  /// просмотренную карточку непрочитанной.
  void _markCurrentAsRead(int index) {
    if (!widget.recordRead) return;
    if (index >= widget.cards.length ||
        !(widget.canMarkRead?.call(index) ?? true)) {
      return;
    }
    final card = widget.cards[index];
    if (_markedCardId == card.id) return;
    _markedCardId = card.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(dayProgressProvider.notifier)
          .markRead(
            card.type,
            date: widget.date,
            markVisited: widget.recordProgress,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final brightness = Theme.of(context).brightness;
    final cardStyle = widget.cards[_index].type.styleFor(brightness);
    return Scaffold(
      body: VerticalCardReader(
        controller: _controller,
        itemCount: _pageCount,
        onPageChanged: (page) {
          setState(() {
            _index = page;
            if (page > _furthest) _furthest = page;
          });
          _markCurrentAsRead(page);
          widget.onPageChanged?.call(page);
        },
        itemBuilder: (context, index) => _cardPage(index),
        header:
            widget.headerBuilder?.call(context, _index) ??
            AppPillBadge(
              label: cardStyle.label,
              background: cardStyle.tagBackground,
              foreground: cardStyle.tagForeground,
              letterSpacing: 0.2,
            ),
        leftRail: RailScrubber(
          count: _pageCount,
          currentIndex: _index,
          onSelect: (page) => _controller.jumpToPage(
            math.min(page, widget.lastScrubbablePage ?? page),
          ),
          child: ProgressDots(
            count: _pageCount,
            currentIndex: _index,
            axis: Axis.vertical,
            accentColors: [
              for (final card in widget.cards)
                card.type.styleFor(brightness).accent,
            ],
          ),
        ),
        actions:
            widget.actionsBuilder?.call(context, _index) ??
            _actionsFor(
              widget.cards[_index],
              widget.wholeCardOf?.call(_index) ?? widget.cards[_index],
              brightness,
              colors.homeSubtitle,
            ),
        onClose: () => Navigator.of(context).pop(),
        closeColor: colors.homeSubtitle,
      ),
    );
  }

  Widget _cardPage(int index) {
    final content =
        widget.pageBuilder?.call(context, index) ??
        CardContent(
          key: ValueKey(widget.cards[index].id),
          card: widget.cards[index],
          showBadge: false,
          scrollable: false,
        );
    final observedContent = ReadingOverflowListener(
      key: ValueKey(widget.cards[index].id),
      onChanged: (needed) {
        if (_fullTextNeeded[widget.cards[index].id] == needed) return;
        setState(() => _fullTextNeeded[widget.cards[index].id] = needed);
      },
      child: content,
    );
    return index == widget.startIndex && !_swipeNudgeHasStarted
        ? CardSwipeNudge(
            onConsumed: () => _swipeNudgeHasStarted = true,
            child: observedContent,
          )
        : observedContent;
  }

  /// Полный текст открывается для показанной страницы [page]: не влезла
  /// именно она. Закладка и отправка относятся ко всей карточке [card].
  Widget _actionsFor(
    DayCard page,
    DayCard card,
    Brightness brightness,
    Color actionColor,
  ) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (_fullTextNeeded[page.id] ?? false) ...[
        ReaderActionButton(
          tooltip: 'Открыть полный текст',
          onPressed: () => _openFullText(page),
          icon: CupertinoIcons.fullscreen,
          color: actionColor,
        ),
        const SizedBox(height: 4),
      ],
      BookmarkButton(
        bookmark: _bookmarkFor(card, brightness),
        iconSize: 28,
        buttonSize: 56,
      ),
      const SizedBox(height: 4),
      AppShareButton(
        text: _shareTextFor(card),
        content: SharedContent.values.byName(card.type.name),
        iconSize: 28,
        buttonSize: 56,
      ),
    ],
  );

  void _openFullText(DayCard card) {
    ref
        .read(analyticsProvider)
        .log(AnalyticsEvent.fullTextOpened(card.type.name));
    Navigator.of(context).push(FullCardTextRoute(card: card));
  }

  /// savedAt — заглушка, момент сохранения ставит сама кнопка.
  Bookmark _bookmarkFor(DayCard card, Brightness brightness) => Bookmark(
    id: card.id,
    kind: BookmarkKind.card,
    text: card.body,
    source: card.source,
    label: card.type.styleFor(brightness).label,
    savedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  String _shareTextFor(DayCard card) => '${card.body}\n\n— ${card.source}';
}
