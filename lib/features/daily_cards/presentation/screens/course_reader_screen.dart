import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_share_button.dart';
import '../../../../core/widgets/reading_overflow_listener.dart';
import '../../../bookmarks/domain/entities/bookmark.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../domain/course_calendar.dart';
import '../../domain/course_topic_titles.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/entities/day_progress.dart';
import '../../domain/split_course_text.dart';
import '../providers/providers.dart';
import '../theme/card_type_style.dart';
import '../widgets/card_content.dart';
import '../widgets/course_contents_button.dart';
import '../widgets/course_contents_sheet.dart';
import '../widgets/reader_progress_rail.dart';
import '../widgets/vertical_card_reader.dart';
import 'course_detail_screen.dart';
import 'full_card_text_screen.dart';

typedef _TopicPage = ({DayCard topic, String text, int index, int count});

/// Тема читается по чанкам. Отдельной страницы завершения нет: тему
/// засчитывает свайп с её последнего чанка к следующей теме. Одно открытие
/// короткой темы прочтением не считается.
class CourseReaderScreen extends ConsumerStatefulWidget {
  const CourseReaderScreen({
    required this.currentTopic,
    this.initialPage = 0,
    super.key,
  });

  final DayCard currentTopic;
  final int initialPage;

  @override
  ConsumerState<CourseReaderScreen> createState() => _CourseReaderScreenState();
}

class _CourseReaderScreenState extends ConsumerState<CourseReaderScreen> {
  final _fullTextNeeded = <String, bool>{};

  late final _pages = _pagesFor(widget.currentTopic);
  late final _controller = PageController(initialPage: _initialIndex);
  late int _index = _initialIndex;
  late var _savedPosition = (
    topic: _topicNumber(widget.currentTopic.id),
    page: _initialIndex - _leading,
  );
  late var _confirmedPosition = (
    topic: _topicNumber(widget.currentTopic.id),
    page: _initialIndex - _leading,
  );
  Future<void> _pendingSave = Future.value();
  Future<void> _pendingCompletion = Future.value();
  final _completing = <int>{};
  final _completed = <int>{};
  final _completionErrors = <int>{};
  bool _loading = false;
  final _loadErrors = <bool>{};
  bool _isDismissing = false;
  bool _canPop = false;
  bool _edgeDismissActive = false;
  double _edgeDismissDistance = 0;
  bool _pulseContents = false;

  int get _initialIndex =>
      _leading + widget.initialPage.clamp(0, _pages.length - 1);
  int get _leading => _topicNumber(_pages.first.topic.id) > 1 ? 1 : 0;
  bool get _hasNext => _topicNumber(_pages.last.topic.id) < courseTopicCount;
  bool get _isBoundary =>
      _index < _leading || _index >= _leading + _pages.length;
  _TopicPage get _visible =>
      _pages[(_index - _leading).clamp(0, _pages.length - 1)];

  @override
  void initState() {
    super.initState();
    // Прогреваем: аналитике при отметке темы нужно состояние «до записи».
    ref
      ..read(completedCourseTopicsProvider)
      ..read(dayProgressProvider);
    final topic = _topicNumber(widget.currentTopic.id);
    if (topic > 1) ref.read(courseTopicByNumberProvider(topic - 1));
    unawaited(_maybeHintContents());
    // Старые версии сохраняли позицию на странице завершения, а ОС могла
    // закрыть приложение раньше записи самого завершения.
    final pastLastChunk = widget.initialPage >= _pages.length;
    if (pastLastChunk || _isFinalChunk(_visible)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_resumeCompletion(topic));
      });
    }
  }

  /// После последней темы листать некуда, поэтому её засчитывает показ
  /// последнего чанка.
  bool _isFinalChunk(_TopicPage page) =>
      _topicNumber(page.topic.id) == courseTopicCount &&
      page.index == page.count - 1;

  Future<void> _resumeCompletion(int topic) async {
    try {
      final completed = await ref.read(completedCourseTopicsProvider.future);
      // Подтверждённый финал восстанавливаем без новой отметки активности дня.
      if (mounted && !completed.contains(topic)) _queueCompletion(topic);
    } on Object {
      if (mounted) setState(() => _completionErrors.add(topic));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_TopicPage> _pagesFor(DayCard card) {
    final chunks = splitCourseText(
      card.body,
    ).where((chunk) => chunk.trim().isNotEmpty).toList();
    if (chunks.isEmpty) chunks.add('');
    return [
      for (var index = 0; index < chunks.length; index++)
        (topic: card, text: chunks[index], index: index, count: chunks.length),
    ];
  }

  void _onPageChanged(int page) {
    final previousIndex = _index - _leading;
    setState(() => _index = page);
    // Свайп вперёд с последнего чанка темы завершает её, даже если следующая
    // тема ещё грузится.
    if (page - _leading == previousIndex + 1 &&
        previousIndex >= 0 &&
        previousIndex < _pages.length) {
      final left = _pages[previousIndex];
      if (left.index == left.count - 1) {
        _queueCompletion(_topicNumber(left.topic.id));
      }
    }
    if (_isBoundary) {
      final previous = page < _leading;
      if (!_loading && !_loadErrors.contains(previous)) {
        unawaited(_loadTopic(previous));
      }
      return;
    }
    final visible = _visible;
    final topic = _topicNumber(visible.topic.id);
    final position = (topic: topic, page: visible.index);
    if (_savedPosition != position) {
      _savedPosition = position;
      _pendingSave = _pendingSave.then((_) => _savePosition(position));
      unawaited(_pendingSave);
    }
    if (_isFinalChunk(visible)) _queueCompletion(topic);
  }

  Future<void> _savePosition(({int topic, int page}) position) async {
    final result = await ref.read(saveCourseTopicProvider)(
      position.topic,
      page: position.page,
    );
    if (!mounted) return;
    if (result is Success<void>) {
      _confirmedPosition = position;
      ref.invalidate(coursePageProvider(position.topic));
      ref.invalidate(courseTopicProvider);
    } else {
      // Отказ не подтверждает позицию: следующий чанк повторит запись.
      if (_savedPosition == position) _savedPosition = _confirmedPosition;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить место чтения')),
      );
    }
  }

  Future<void> _loadTopic(bool previous) async {
    if (_loading || _isDismissing) return;
    final number = previous
        ? _topicNumber(_pages.first.topic.id) - 1
        : _topicNumber(_pages.last.topic.id) + 1;
    if (number < 1 || number > courseTopicCount) return;
    setState(() {
      _loading = true;
      _loadErrors.remove(previous);
    });
    try {
      final card = await ref.read(courseTopicByNumberProvider(number).future);
      if (!mounted) return;
      final added = _pagesFor(card);
      final oldLeading = _leading;
      final oldIndex = _index;
      setState(() {
        if (previous) {
          _pages.insertAll(0, added);
          // При движении назад открываем последний чанк предыдущей темы.
          _index = oldIndex == 0
              ? _leading + added.length - 1
              : oldIndex + added.length + _leading - oldLeading;
        } else {
          _pages.addAll(added);
        }
        _loading = false;
      });
      if (previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_controller.hasClients) return;
          _controller.jumpToPage(_index);
          _onPageChanged(_index);
        });
      } else {
        _onPageChanged(_index);
      }
    } on Object catch (error) {
      if (!mounted) return;
      ref
          .read(analyticsProvider)
          .log(
            AnalyticsEvent.contentLoadFailed(
              content: LoadedContent.courseTopic,
              kind: failureKindOf(error),
            ),
          );
      setState(() {
        _loading = false;
        _loadErrors.add(previous);
      });
      // За время запроса пользователь мог перейти к противоположной границе.
      if (_isBoundary && (_index < _leading) != previous) {
        _onPageChanged(_index);
      }
    }
  }

  /// Плашка темы похожа на подпись, поэтому при первом открытии курса она
  /// пульсирует: на неё можно нажать и открыть оглавление.
  Future<void> _maybeHintContents() async {
    final hints = ref.read(courseHintRepositoryProvider);
    final shown = await hints.contentsHintShown();
    if (!mounted || shown is! Success<bool> || shown.value) return;
    setState(() => _pulseContents = true);
    await hints.markContentsHintShown();
  }

  Future<void> _openContents(int currentTopic) async {
    ref
        .read(analyticsProvider)
        .log(AnalyticsEvent.courseInfoOpened(CourseInfoScreen.contents));
    final completed = {
      ...?ref.read(completedCourseTopicsProvider).value,
      ..._completed,
    };
    final selected = await showCourseContentsSheet(
      context,
      titles: courseTopicTitles,
      currentTopic: currentTopic,
      completed: completed,
    );
    if (selected != null && mounted) unawaited(_jumpToTopic(selected));
  }

  /// Переход по оглавлению переносит курс на выбранную тему, как закладка в
  /// книге: лента начинается заново с её первой страницы и сохраняется как
  /// место чтения. Тема, с которой ушли, при этом не засчитывается.
  Future<void> _jumpToTopic(int number) async {
    if (_loading || _isDismissing) return;
    setState(() => _loading = true);
    try {
      final card = await ref.read(courseTopicByNumberProvider(number).future);
      if (!mounted) return;
      final pages = _pagesFor(card);
      setState(() {
        _pages
          ..clear()
          ..addAll(pages);
        _loadErrors.clear();
        // Индекс ставим до прыжка: тогда смена страницы не выглядит свайпом
        // вперёд с последнего чанка и не засчитывает прежнюю тему.
        _index = _leading;
        _loading = false;
      });
      if (number > 1) ref.read(courseTopicByNumberProvider(number - 1));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        _controller.jumpToPage(_index);
        _onPageChanged(_index);
      });
    } on Object catch (error) {
      if (!mounted) return;
      ref
          .read(analyticsProvider)
          .log(
            AnalyticsEvent.contentLoadFailed(
              content: LoadedContent.courseTopic,
              kind: failureKindOf(error),
            ),
          );
      setState(() => _loading = false);
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text('Тема недоступна')));
    }
  }

  void _queueCompletion(int topic) {
    if (_completed.contains(topic) ||
        _completing.contains(topic) ||
        _isDismissing) {
      return;
    }
    setState(() {
      _completing.add(topic);
      _completionErrors.remove(topic);
    });
    _pendingCompletion = _pendingCompletion.then((_) => _completeTopic(topic));
    unawaited(_pendingCompletion);
  }

  Future<void> _completeTopic(int topic) async {
    // Синхронно, чтобы не задерживать запись: провайдеры прогреты в initState.
    final completedBefore = ref.read(completedCourseTopicsProvider).value;
    final litBefore = ref
        .read(dayProgressProvider)
        .value
        ?.isLit(DateTime.now());
    final result = await ref.read(completeCourseTopicProvider)(topic);
    if (!mounted) return;
    setState(() {
      _completing.remove(topic);
      if (result is Success) {
        _completed.add(topic);
      } else {
        _completionErrors.add(topic);
      }
    });
    if (result is! Success) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: const Text('Не удалось сохранить прогресс'),
          action: SnackBarAction(
            label: 'Повторить сохранение',
            onPressed: () => _queueCompletion(topic),
          ),
        ),
      );
    }
    // Тема могла сохраниться даже при неудачной записи активности дня.
    ref.invalidate(completedCourseTopicsProvider);
    ref.invalidate(courseTopicProvider);
    if (result is Success) {
      ref.invalidate(dayProgressProvider);
      // После инвалидации: лампаду сравниваем с уже перезагруженным днём.
      unawaited(_logCompletion(topic, completedBefore, litBefore));
    }
  }

  void _openFullText(Route<void> route) {
    ref.read(analyticsProvider).log(AnalyticsEvent.fullTextOpened('basics'));
    Navigator.of(context).push(route);
  }

  /// Тема засчитывается и при восстановлении после сбоя: в аналитику идёт
  /// только новая отметка. Лампада сравнивается с прогрессом до записи.
  Future<void> _logCompletion(
    int topic,
    Set<int>? completedBefore,
    bool? litBefore,
  ) async {
    final analytics = ref.read(analyticsProvider);
    if (completedBefore != null && !completedBefore.contains(topic)) {
      final total = completedBefore.length + 1;
      analytics.log(
        AnalyticsEvent.courseTopicCompleted(
          topic: topic,
          topicsCompleted: total,
        ),
      );
      if (total >= courseTopicCount) {
        analytics.log(AnalyticsEvent.courseFinished());
      }
    }
    if (litBefore ?? true) return;
    final DayProgress after;
    try {
      after = await ref.read(dayProgressProvider.future);
    } on Object {
      return;
    }
    final today = DateTime.now();
    if (!after.isLit(today)) return;
    analytics.log(
      AnalyticsEvent.lampLit(
        source: LampSource.course,
        streak: after.streakOn(today),
        restarted: after.streakOn(today) == 1,
      ),
    );
  }

  Future<void> _dismiss() async {
    if (_isDismissing) return;
    setState(() => _isDismissing = true);
    await _pendingSave;
    await _pendingCompletion;
    if (!mounted) return;
    setState(() => _canPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  void _onEdgeDismissStart(DragStartDetails details) {
    _edgeDismissActive = details.localPosition.dx <= 32;
    _edgeDismissDistance = 0;
  }

  void _onEdgeDismissUpdate(DragUpdateDetails details) {
    if (_edgeDismissActive) {
      _edgeDismissDistance += details.primaryDelta ?? 0;
    }
  }

  void _onEdgeDismissEnd(DragEndDetails details) {
    final shouldDismiss =
        _edgeDismissActive &&
        (_edgeDismissDistance >= 80 || (details.primaryVelocity ?? 0) >= 500);
    _edgeDismissActive = false;
    _edgeDismissDistance = 0;
    if (shouldDismiss) unawaited(_dismiss());
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final brightness = Theme.of(context).brightness;
    final style = CardType.basics.styleFor(brightness);
    final visible = _visible;
    final card = visible.topic;
    final topic = _topicNumber(card.id);
    return PopScope<void>(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_dismiss());
      },
      child: Scaffold(
        // fullscreenDialog убирает системный edge-back жест, поэтому сохраняем
        // его явно и направляем в тот же выход с ожиданием записи позиции.
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: _onEdgeDismissStart,
          onHorizontalDragUpdate: _onEdgeDismissUpdate,
          onHorizontalDragEnd: _onEdgeDismissEnd,
          onHorizontalDragCancel: () => _edgeDismissActive = false,
          child: AbsorbPointer(
            // Новые свайпы и маршруты не должны менять очередь записей
            // или верхний экран, пока выход ожидает сохранения.
            absorbing: _isDismissing,
            child: VerticalCardReader(
              controller: _controller,
              itemCount: _leading + _pages.length + (_hasNext ? 1 : 0),
              onPageChanged: _onPageChanged,
              itemBuilder: (_, page) {
                final index = page - _leading;
                if (index < 0 || index >= _pages.length) {
                  return Center(
                    child: !_loadErrors.contains(index < 0)
                        ? const CircularProgressIndicator()
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Тема недоступна'),
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(analyticsProvider)
                                      .log(
                                        AnalyticsEvent.contentRetryTapped(
                                          LoadedContent.courseTopic,
                                        ),
                                      );
                                  final previous = index < 0;
                                  final number = previous
                                      ? _topicNumber(_pages.first.topic.id) - 1
                                      : _topicNumber(_pages.last.topic.id) + 1;
                                  ref.invalidate(
                                    courseTopicByNumberProvider(number),
                                  );
                                  unawaited(_loadTopic(previous));
                                },
                                child: const Text('Повторить'),
                              ),
                            ],
                          ),
                  );
                }
                final item = _pages[index];
                final pageId = '${item.topic.id}-${item.index}';
                return ReadingOverflowListener(
                  key: ValueKey(pageId),
                  onChanged: (needed) {
                    if (_fullTextNeeded[pageId] == needed) return;
                    setState(() => _fullTextNeeded[pageId] = needed);
                  },
                  child: CardContent(
                    card: item.topic.copyWith(
                      body: item.text.trim(),
                      title: null,
                    ),
                    showBadge: false,
                    showSource: false,
                    scrollable: false,
                  ),
                );
              },
              headerInteractive: true,
              header: CourseContentsButton(
                label: 'Основы веры · Тема №$topic',
                background: style.tagBackground,
                foreground: style.tagForeground,
                pulse: _pulseContents,
                onPressed: () => unawaited(_openContents(topic)),
              ),
              leftRail: ReaderProgressRail(
                key: ValueKey(card.id),
                count: visible.count,
                currentIndex: _isBoundary ? -1 : visible.index,
                accent: style.accent,
                // Граница PageView может показывать заглушку, но точки всё ещё
                // принадлежат последней настоящей теме в _pages.
                onSelect: (index) {
                  final topicStart =
                      _pages.indexWhere((page) => page.topic.id == card.id) +
                      _leading;
                  _controller.jumpToPage(topicStart + index);
                },
              ),
              actions: _isBoundary
                  ? const SizedBox.shrink()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_fullTextNeeded['${card.id}-${visible.index}'] ??
                            false)
                          ReaderActionButton(
                            tooltip: 'Открыть полный текст',
                            onPressed: () => _openFullText(
                              FullCardTextRoute(
                                card: card.copyWith(
                                  body: visible.text.trim(),
                                  title: null,
                                ),
                                showSource: false,
                              ),
                            ),
                            icon: CupertinoIcons.fullscreen,
                            color: colors.homeSubtitle,
                          ),
                        BookmarkButton(
                          bookmark: Bookmark(
                            id: '${card.id}-page-${visible.index}',
                            kind: BookmarkKind.card,
                            text: visible.text.trim(),
                            source: card.source,
                            label: style.label,
                            savedAt: DateTime.fromMillisecondsSinceEpoch(0),
                          ),
                          iconSize: 28,
                          buttonSize: 56,
                        ),
                        AppShareButton(
                          text: '${card.body}\n\n— ${card.source}',
                          content: SharedContent.basics,
                          iconSize: 28,
                          buttonSize: 56,
                        ),
                      ],
                    ),
              onClose: () => unawaited(_dismiss()),
              closeColor: colors.homeSubtitle,
              topLeftAction: IconButton(
                tooltip: 'О курсе',
                onPressed: () {
                  ref
                      .read(analyticsProvider)
                      .log(
                        AnalyticsEvent.courseInfoOpened(
                          CourseInfoScreen.courseDetail,
                        ),
                      );
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CourseDetailScreen(),
                    ),
                  );
                },
                icon: Icon(
                  CupertinoIcons.info,
                  size: 22,
                  color: colors.homeSubtitle,
                ),
              ),
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
