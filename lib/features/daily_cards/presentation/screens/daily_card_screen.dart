import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/day_card.dart';
import '../providers/providers.dart';
import '../theme/card_type_style.dart';
import '../widgets/card_content.dart';
import '../widgets/daily_card_action_button.dart';
import '../widgets/home_button.dart';
import '../widgets/progress_dots.dart';
import '../widgets/session_done_view.dart';

/// Порог скорости свайпа (лог.px/с), после которого жест засчитывается
/// как «Дальше»/«Назад» — короткий вялый драг игнорируется.
const _swipeVelocityThreshold = 300.0;

/// Ядро продукта: ОДНА карточка на весь экран. «Дальше» — добровольно.
/// Прочитанные карточки отмечаются в прогрессе дня; на последней — «Готово»
/// и экран завершения. Листать можно свайпом влево/вправо. Кнопка «домой»
/// слева сверху и «На главный экран» на завершении — pop к Home.
class DailyCardScreen extends ConsumerStatefulWidget {
  const DailyCardScreen({super.key, this.startIndex = 0});

  /// Индекс карточки, с которой открыться (первая непрочитанная).
  /// Ожидается валидным для списка дня; build дополнительно клампит его
  /// от RangeError, если данные изменились.
  final int startIndex;

  @override
  ConsumerState<DailyCardScreen> createState() => _DailyCardScreenState();
}

class _DailyCardScreenState extends ConsumerState<DailyCardScreen> {
  late int _index = widget.startIndex;
  bool _done = false;
  int? _markedIndex;

  /// Засчитывает карточку прочитанной, как только она стала текущей —
  /// не дожидаясь «Дальше». Иначе если уйти домой не долистав до конца,
  /// уже просмотренная карточка осталась бы непрочитанной.
  void _markCurrentAsRead(List<DayCard> list, int index) {
    if (_markedIndex == index) return;
    _markedIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(dayProgressProvider.notifier).markRead(list[index].type);
    });
  }

  Future<void> _next(List<DayCard> list) async {
    final index = _index.clamp(0, list.length - 1);
    final notifier = ref.read(dayProgressProvider.notifier);
    if (index >= list.length - 1) {
      // Ждём персист (markRead, потом completeDay — тот же ключ prefs,
      // параллельно затёрли бы друг друга) перед показом done-экрана.
      // Иначе он на миг покажет старую серию, и цифра дёрнется после отрисовки.
      await notifier.markRead(list[index].type);
      await notifier.completeDay();
      if (!mounted) return;
      setState(() => _done = true);
    } else {
      notifier.markRead(list[index].type);
      setState(() => _index = index + 1);
    }
  }

  void _previous() {
    if (_done) {
      setState(() => _done = false);
    } else if (_index > 0) {
      setState(() => _index--);
    }
  }

  void _handleSwipe(DragEndDetails details, List<DayCard> list) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity <= -_swipeVelocityThreshold) {
      _next(list);
    } else if (velocity >= _swipeVelocityThreshold) {
      _previous();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(todayCardsProvider);
    final progress = ref.watch(dayProgressProvider);
    final streakDays = progress.value?.streakDays ?? 0;
    final colors = AppColorsExtension.of(context);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: SafeArea(
        child: cards.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          // TODO: спокойный экран ошибки, не стектрейс.
          error: (e, _) => Center(child: Text('$e')),
          data: (today) {
            final list = today.cards;
            // Защита от RangeError, если данные обновились и список стал короче.
            final index = _index.clamp(0, list.length - 1);
            final isLast = index == list.length - 1;
            if (!_done) _markCurrentAsRead(list, index);

            return Stack(
              children: [
                Positioned(
                  top: 12,
                  left: 20,
                  child: HomeButton(onPressed: () => Navigator.of(context).pop()),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 24),
                  child: Column(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragEnd: (details) =>
                              _handleSwipe(details, list),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              // Старый текст уходит быстрее нового — иначе оба
                              // фейда идут одинаково и текст накладывается.
                              reverseDuration: const Duration(milliseconds: 120),
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween(
                                    begin: const Offset(0, 0.02),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                              child: _done
                                  ? (today.staleDate != null
                                      ? SessionDoneStaleView(
                                          key: const ValueKey('done'),
                                          staleDate: today.staleDate!,
                                          onHome: () =>
                                              Navigator.of(context).pop(),
                                        )
                                      : SessionDoneView(
                                          key: const ValueKey('done'),
                                          streakDays: streakDays,
                                          onHome: () =>
                                              Navigator.of(context).pop(),
                                        ))
                                  : CardContent(
                                      key: ValueKey(list[index].id),
                                      card: list[index],
                                    ),
                            ),
                          ),
                        ),
                      ),
                      // AnimatedSize вместо мгновенного условного удаления —
                      // иначе Expanded резко «прыгает» на освободившееся
                      // место прямо во время фейда карточки в done-экран.
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: Alignment.topCenter,
                        child: _done
                            ? const SizedBox.shrink()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 20),
                                  ProgressDots(
                                    count: list.length,
                                    currentIndex: index,
                                    accentColors: [
                                      for (final card in list)
                                        card.type.styleFor(brightness).accent,
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  isLast
                                      ? DailyCardDoneButton(
                                          color: colors.accent,
                                          onPressed: () => _next(list),
                                        )
                                      : DailyCardNextButton(
                                          color: colors.accent,
                                          onPressed: () => _next(list),
                                        ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
