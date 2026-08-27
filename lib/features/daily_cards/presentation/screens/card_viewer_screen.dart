import 'package:flutter/cupertino.dart' show CupertinoIcons;
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

/// Скорость свайпа вниз (лог.px/с), после которой просмотрщик закрывается.
const _dismissVelocity = 700.0;
const _readerHeaderHeight = 48.0;

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
    super.key,
  });

  /// Карточки-страницы. Евангелие и курс идут отдельными треками и сюда не
  /// входят.
  final List<DayCard> cards;
  final int startIndex;
  final DateTime date;

  /// Засчитывать ли дату посещённой. Само прочтение пишется всегда.
  final bool recordProgress;

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

  void _handleVerticalDrag(DragEndDetails details) {
    if ((details.primaryVelocity ?? 0) >= _dismissVelocity) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final brightness = Theme.of(context).brightness;
    final cardStyle = widget.cards[_index].type.styleFor(brightness);
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragEnd: _handleVerticalDrag,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: _readerHeaderHeight),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pageCount,
                      onPageChanged: (page) {
                        setState(() => _index = page);
                        _markCurrentAsRead(page);
                      },
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 34),
                        child: Center(child: _cardPage(index)),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: true,
                    maintainAnimation: true,
                    maintainSize: true,
                    maintainState: true,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 20),
                          ProgressDots(
                            count: _pageCount,
                            currentIndex: _index,
                            accentColors: [
                              for (final card in widget.cards)
                                card.type.styleFor(brightness).accent,
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
              // Закрыть можно и крестиком, и свайпом вниз — привычная для
              // iOS пара жестов для модального экрана.
              Positioned(
                top: 0,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    CupertinoIcons.xmark,
                    size: 22,
                    color: colors.homeSubtitle,
                  ),
                  tooltip: 'Закрыть',
                ),
              ),
              Positioned(
                top: 8,
                left: 80,
                right: 80,
                child: IgnorePointer(
                  child: Center(
                    child: AppPillBadge(
                      label: cardStyle.label,
                      background: cardStyle.tagBackground,
                      foreground: cardStyle.tagForeground,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BookmarkButton(
                      bookmark: _bookmarkFor(widget.cards[_index], brightness),
                    ),
                    AppShareButton(text: _shareTextFor(widget.cards[_index])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardPage(int index) {
    final content = CardContent(
      key: ValueKey(widget.cards[index].id),
      card: widget.cards[index],
      showBadge: false,
    );
    final spacedContent = Padding(
      padding: const EdgeInsets.only(top: _readerHeaderHeight),
      child: content,
    );
    return index == widget.startIndex && !_swipeNudgeHasStarted
        ? CardSwipeNudge(
            onConsumed: () => _swipeNudgeHasStarted = true,
            child: spacedContent,
          )
        : spacedContent;
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
