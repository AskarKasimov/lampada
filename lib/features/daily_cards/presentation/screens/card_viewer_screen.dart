import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../bookmarks/domain/entities/bookmark.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../../reading/presentation/screens/reading_screen.dart';
import '../../domain/entities/day_card.dart';
import '../providers/providers.dart';
import '../theme/card_type_style.dart';
import '../widgets/card_content.dart';
import '../widgets/daily_card_action_button.dart';
import '../widgets/progress_dots.dart';
import '../widgets/session_done_view.dart';

/// Скорость свайпа вниз (лог.px/с), после которой просмотрщик закрывается.
const _dismissVelocity = 700.0;

/// Полноэкранный просмотр карточек дня — без таб-бара и вообще без хрома
/// вокруг: на экране остаётся одна мысль, как требует §6.
///
/// Отдельный маршрут поверх шелла, а не содержимое вкладки: только так
/// нижняя навигация не отъедает низ экрана у текста.
class CardViewerScreen extends ConsumerStatefulWidget {
  const CardViewerScreen({
    required this.cards,
    required this.startIndex,
    required this.recordProgress,
    super.key,
    this.reading,
  });

  /// Карточки-страницы. Карточки чтения здесь нет: она не текст, а вход
  /// в ридер, и своей страницы не получает — см. [reading].
  final List<DayCard> cards;
  final int startIndex;

  /// Писать ли прогресс. Для чужих дат false: «Лампадка» отмечает дни, когда
  /// юзер заходил ЗА КОНТЕНТОМ ЭТОГО ДНЯ, и чтение вчерашнего не должно
  /// задним числом зажигать вчерашний огонёк.
  final bool recordProgress;

  /// Чтение дня, если оно есть. Своей страницы не имеет: показывать экран
  /// с одной ссылкой «Ин.10:1–9» и кнопкой «Читать» — лишний шаг, ридер
  /// открывается сразу с последней карточки.
  final DayCard? reading;

  @override
  ConsumerState<CardViewerScreen> createState() => _CardViewerScreenState();
}

class _CardViewerScreenState extends ConsumerState<CardViewerScreen> {
  late final PageController _controller = PageController(
    initialPage: widget.startIndex,
  );
  late int _index = widget.startIndex;
  int? _markedIndex;

  /// Экран завершения — последняя страница, сразу за карточками. Он про
  /// «на сегодня довольно», поэтому у чужих дней его нет.
  bool get _hasDonePage => widget.recordProgress;

  int get _pageCount => widget.cards.length + (_hasDonePage ? 1 : 0);

  /// Точек столько, сколько частей у дня, включая чтение: иначе с последней
  /// карточки кажется, что день кончился, а он нет.
  int get _stepCount => widget.cards.length + (widget.reading != null ? 1 : 0);

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
    if (!widget.recordProgress) return;
    if (index >= widget.cards.length || _markedIndex == index) return;
    _markedIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(dayProgressProvider.notifier).markRead(widget.cards[index].type);
    });
  }

  void _next() {
    if (_index >= _pageCount - 1) {
      Navigator.of(context).pop();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  /// Ридер открывается прямо с последней карточки. Дочитал отрывок —
  /// показываем завершение дня; вышел раньше — остаёмся на карточке.
  Future<void> _openReader() async {
    final card = widget.reading!;
    if (widget.recordProgress) {
      ref.read(dayProgressProvider.notifier).markRead(card.type);
    }
    var finished = false;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReadingScreen(
          reference: card.reference!,
          onFinished: () => finished = true,
        ),
      ),
    );
    if (!mounted || !finished || !_hasDonePage) return;
    _controller.animateToPage(
      _pageCount - 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
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
    final onDonePage = _index >= widget.cards.length;
    final bookmarkIndex = onDonePage ? widget.cards.length - 1 : _index;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragEnd: _handleVerticalDrag,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 48),
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
                        child: Center(
                          child: index < widget.cards.length
                              ? CardContent(
                                  key: ValueKey(widget.cards[index].id),
                                  card: widget.cards[index],
                                )
                              : SessionDoneView(
                                  onDone: () => Navigator.of(context).pop(),
                                ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: !onDonePage,
                    maintainAnimation: true,
                    maintainSize: true,
                    maintainState: true,
                    child: _footer(colors, brightness),
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
                  icon: const Icon(Icons.close),
                  color: colors.homeIcon,
                  tooltip: 'Закрыть',
                ),
              ),
              Positioned(
                top: 0,
                left: 8,
                child: Visibility(
                  visible: !onDonePage,
                  maintainAnimation: true,
                  maintainSize: true,
                  maintainState: true,
                  child: BookmarkButton(
                    bookmark: _bookmarkFor(
                      widget.cards[bookmarkIndex],
                      brightness,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(AppColorsExtension colors, Brightness brightness) {
    final isLastCard = _index == widget.cards.length - 1;
    final reading = widget.reading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        ProgressDots(
          count: _stepCount,
          currentIndex: _index,
          accentColors: [
            for (final c in widget.cards) c.type.styleFor(brightness).accent,
            if (reading != null) reading.type.styleFor(brightness).accent,
          ],
        ),
        const SizedBox(height: 20),
        if (isLastCard && reading != null)
          DailyCardReadButton(color: colors.accent, onPressed: _openReader)
        else if (isLastCard && !_hasDonePage)
          DailyCardDoneButton(
            color: colors.accent,
            onPressed: () => Navigator.of(context).pop(),
          )
        else
          DailyCardNextButton(color: colors.accent, onPressed: _next),
      ],
    );
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
}
