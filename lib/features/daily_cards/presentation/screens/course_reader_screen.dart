import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_link_button.dart';
import '../../../../core/widgets/app_pill_badge.dart';
import '../../../../core/widgets/app_share_button.dart';
import '../../../bookmarks/domain/entities/bookmark.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../domain/course_calendar.dart';
import '../../domain/entities/day_card.dart';
import '../providers/providers.dart';
import '../theme/card_type_style.dart';
import '../widgets/card_content.dart';
import '../widgets/vertical_card_reader.dart';
import 'full_card_text_screen.dart';

/// Полноэкранное чтение личного курса «Основы веры».
///
/// Открывается на последней теме юзера. Вертикальный жест вверх открывает
/// следующие темы, вниз — предыдущие.
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
        scrollable: false,
      );
    }

    final topic = _topicForPage(page);
    return ref
        .watch(courseTopicByNumberProvider(topic))
        .when(
          data: (card) => CardContent(
            key: ValueKey(card.id),
            card: card,
            showBadge: false,
            scrollable: false,
          ),
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
    final basicsStyle = CardType.basics.styleFor(brightness);
    final currentCard = _cardForPage(_index);
    final visibleTopic = _topicForPage(_index);

    return PopScope<void>(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_dismiss());
      },
      child: Scaffold(
        body: VerticalCardReader(
          controller: _controller,
          itemCount: courseTopicCount,
          reverse: true,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, page) => _contentForPage(page, colors),
          header: AppPillBadge(
            label: 'Основы веры',
            background: basicsStyle.tagBackground,
            foreground: basicsStyle.tagForeground,
            letterSpacing: 0.2,
          ),
          leftRail: _CourseProgressRail(
            topic: visibleTopic,
            total: courseTopicCount,
            color: colors.textSecondary,
          ),
          actions: _actionsFor(currentCard, brightness, colors.homeSubtitle),
          onClose: () => unawaited(_dismiss()),
          closeColor: colors.homeSubtitle,
        ),
      ),
    );
  }

  Widget _actionsFor(DayCard? card, Brightness brightness, Color actionColor) {
    if (card == null) return const SizedBox.square(dimension: 56);
    return Column(
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
        AppShareButton(text: _shareTextFor(card), iconSize: 28, buttonSize: 56),
      ],
    );
  }

  void _openFullText(DayCard card) {
    Navigator.of(context).push(FullCardTextRoute(card: card));
  }
}

class _CourseProgressRail extends StatelessWidget {
  const _CourseProgressRail({
    required this.topic,
    required this.total,
    required this.color,
  });

  final int topic;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    'Тема\n$topic\nиз\n$total',
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 12, color: color),
  );
}

int _topicNumber(String id) {
  final match = RegExp(r'^basics-topic-(\d+)$').firstMatch(id);
  return int.tryParse(match?.group(1) ?? '') ?? 1;
}
