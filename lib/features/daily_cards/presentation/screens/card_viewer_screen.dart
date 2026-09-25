import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_pill_badge.dart';
import '../../../../core/widgets/app_share_button.dart';
import '../../../bookmarks/domain/entities/bookmark.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../domain/entities/day_card.dart';
import '../providers/providers.dart';
import '../theme/card_type_style.dart';
import '../widgets/card_content.dart';
import '../widgets/card_swipe_nudge.dart';
import '../widgets/progress_dots.dart';
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
    this.pageBuilder,
    super.key,
  });

  /// Карточки-страницы. Евангелие и курс идут отдельными треками и сюда не
  /// входят.
  final List<DayCard> cards;
  final int startIndex;
  final DateTime date;

  /// Засчитывать ли дату посещённой.
  final bool recordProgress;

  /// Записывать ли прочтение карточек. Для будущих дат выключено: их точки
  /// непрочитанного должны оставаться видимыми после предварительного чтения.
  final bool recordRead;

  /// Дополнительное содержимое страницы. Рамка, жесты, шапка и действия
  /// остаются общими для всех карточек; меняется только центральный материал.
  final CardPageBuilder? pageBuilder;

  @override
  ConsumerState<CardViewerScreen> createState() => _CardViewerScreenState();
}

class _CardViewerScreenState extends ConsumerState<CardViewerScreen> {
  late final PageController _controller = PageController(
    initialPage: widget.startIndex,
  );
  late int _index = widget.startIndex;
  int? _markedIndex;
  var _swipeNudgeHasStarted = false;

  int get _pageCount => widget.cards.length;

  @override
  void initState() {
    super.initState();
    _markCurrentAsRead(widget.startIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Засчитывает карточку прочитанной сразу при показе, не дожидаясь
  /// «Дальше» — иначе, закрыв просмотрщик раньше конца, юзер оставил бы
  /// просмотренную карточку непрочитанной.
  void _markCurrentAsRead(int index) {
    if (!widget.recordRead) return;
    if (index >= widget.cards.length || _markedIndex == index) return;
    _markedIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(dayProgressProvider.notifier)
          .markRead(
            widget.cards[index].type,
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
          setState(() => _index = page);
          _markCurrentAsRead(page);
        },
        itemBuilder: (context, index) => _cardPage(index),
        header: AppPillBadge(
          label: cardStyle.label,
          background: cardStyle.tagBackground,
          foreground: cardStyle.tagForeground,
          letterSpacing: 0.2,
        ),
        leftRail: ProgressDots(
          count: _pageCount,
          currentIndex: _index,
          axis: Axis.vertical,
          accentColors: [
            for (final card in widget.cards)
              card.type.styleFor(brightness).accent,
          ],
        ),
        actions: _actionsFor(
          widget.cards[_index],
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
    return index == widget.startIndex && !_swipeNudgeHasStarted
        ? CardSwipeNudge(
            onConsumed: () => _swipeNudgeHasStarted = true,
            child: content,
          )
        : content;
  }

  Widget _actionsFor(DayCard card, Brightness brightness, Color actionColor) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (CardContent.needsFullText(card)) ...[
            ReaderActionButton(
              tooltip: 'Открыть полный текст',
              onPressed: () => _openFullText(card),
              icon: Icons.aspect_ratio_outlined,
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
            iconSize: 28,
            buttonSize: 56,
          ),
        ],
      );

  void _openFullText(DayCard card) {
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
