import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_link_button.dart';
import '../../../../core/widgets/app_share_button.dart';
import '../../../bookmarks/domain/entities/bookmark.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../domain/course_calendar.dart';
import '../../domain/entities/day_card.dart';
import '../providers/providers.dart';
import '../theme/card_type_style.dart';
import '../widgets/card_content.dart';

const _dismissVelocity = 700.0;

/// Полноэкранное чтение личного курса «Основы веры».
///
/// Открывается на последней теме юзера. Движение вправо открывает предыдущие
/// темы, движение влево — следующие.
class CourseReaderScreen extends ConsumerStatefulWidget {
  const CourseReaderScreen({required this.currentTopic, super.key});

  final DayCard currentTopic;

  @override
  ConsumerState<CourseReaderScreen> createState() => _CourseReaderScreenState();
}

class _CourseReaderScreenState extends ConsumerState<CourseReaderScreen> {
  late final int _currentTopicNumber = _topicNumber(widget.currentTopic.id);
  late final _controller = PageController(
    initialPage: _pageForTopic(_currentTopicNumber),
  );
  late var _index = _pageForTopic(_currentTopicNumber);
  Future<void> _pendingSave = Future.value();
  var _isDismissing = false;
  var _canPop = false;

  @override
  void initState() {
    super.initState();
    _markCurrentTopicAsReadInDay();
    if (_currentTopicNumber > 1) {
      // Запускаем загрузку первой исторической страницы до жеста пользователя.
      ref.read(courseTopicByNumberProvider(_currentTopicNumber - 1));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _markCurrentTopicAsReadInDay() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final saved = await ref
          .read(dayProgressProvider.notifier)
          .markRead(CardType.basics);
      if (!saved && mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Не удалось сохранить прогресс'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _handleVerticalDrag(DragEndDetails details) {
    if ((details.primaryVelocity ?? 0) >= _dismissVelocity) {
      unawaited(_dismiss());
    }
  }

  int _pageForTopic(int topic) => courseTopicCount - topic;

  int _topicForPage(int page) => courseTopicCount - page;

  void _onPageChanged(int page) {
    setState(() => _index = page);
    _pendingSave = _saveVisibleTopic(_topicForPage(page));
    unawaited(_pendingSave);
  }

  Future<void> _saveVisibleTopic(int topic) async {
    try {
      if (topic != _currentTopicNumber) {
        await ref.read(courseTopicByNumberProvider(topic).future);
      }
    } on Object {
      return;
    }
    if (!mounted || _topicForPage(_index) != topic) return;
    final result = await ref.read(saveCourseTopicProvider)(topic);
    if (!mounted) return;
    if (result is Success<void>) {
      ref.invalidate(courseTopicProvider);
      return;
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Не удалось сохранить прогресс'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _dismiss() async {
    if (_isDismissing) return;
    _isDismissing = true;
    await _pendingSave;
    if (!mounted) return;
    setState(() => _canPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  DayCard? _cardForPage(int page) {
    if (_topicForPage(page) == _currentTopicNumber) return widget.currentTopic;
    return ref.watch(courseTopicByNumberProvider(_topicForPage(page))).value;
  }

  Widget _contentForPage(int page, AppColorsExtension colors) {
    if (_topicForPage(page) == _currentTopicNumber) {
      return CardContent(
        key: ValueKey(widget.currentTopic.id),
        card: widget.currentTopic,
        showBadge: false,
      );
    }

    final topic = _topicForPage(page);
    return ref
        .watch(courseTopicByNumberProvider(topic))
        .when(
          data: (card) =>
              CardContent(key: ValueKey(card.id), card: card, showBadge: false),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Тема недоступна',
                  style: TextStyle(fontSize: 14, color: colors.ink),
                ),
                const SizedBox(height: 6),
                Text(
                  'Не удалось загрузить эту тему',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: colors.homeSubtitle),
                ),
                const SizedBox(height: 12),
                AppLinkButton(
                  label: 'Повторить',
                  color: colors.link,
                  fontSize: 12,
                  onPressed: () {
                    ref.invalidate(courseTopicByNumberProvider(topic));
                    _pendingSave = _saveVisibleTopic(topic);
                    unawaited(_pendingSave);
                  },
                ),
              ],
            ),
          ),
        );
  }

  Bookmark _bookmarkFor(DayCard card, Brightness brightness) => Bookmark(
    id: card.id,
    kind: BookmarkKind.card,
    text: card.body,
    source: card.source,
    label: card.type.styleFor(brightness).label,
    savedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  String _shareTextFor(DayCard card) => '${card.body}\n\n— ${card.source}';

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final brightness = Theme.of(context).brightness;
    final currentCard = _cardForPage(_index);
    final visibleTopic = _topicForPage(_index);

    return PopScope<void>(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_dismiss());
      },
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragEnd: _handleVerticalDrag,
          child: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(34, 48, 34, 48),
                  child: PageView.builder(
                    controller: _controller,
                    reverse: true,
                    itemCount: courseTopicCount,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, page) =>
                        _contentForPage(page, colors),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 8,
                  child: currentCard == null
                      ? const SizedBox.square(dimension: 40)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BookmarkButton(
                              bookmark: _bookmarkFor(currentCard, brightness),
                            ),
                            AppShareButton(text: _shareTextFor(currentCard)),
                          ],
                        ),
                ),
                Positioned(
                  top: 11,
                  left: 56,
                  right: 56,
                  child: Text(
                    'Основы веры',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: colors.ink),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 8,
                  child: IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.chevron_left,
                          size: 12,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Тема $visibleTopic из $courseTopicCount',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 12,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 8,
                  child: IconButton(
                    onPressed: () => unawaited(_dismiss()),
                    icon: Icon(
                      CupertinoIcons.xmark,
                      size: 22,
                      color: colors.homeSubtitle,
                    ),
                    tooltip: 'Закрыть',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

int _topicNumber(String id) {
  final match = RegExp(r'^basics-topic-(\d+)$').firstMatch(id);
  return int.tryParse(match?.group(1) ?? '') ?? 1;
}
