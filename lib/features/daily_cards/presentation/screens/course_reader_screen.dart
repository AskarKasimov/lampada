import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_pill_badge.dart';
import '../../../../core/widgets/app_share_button.dart';
import '../../../bookmarks/domain/entities/bookmark.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../domain/course_calendar.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/split_course_text.dart';
import '../providers/providers.dart';
import '../theme/card_type_style.dart';
import '../widgets/card_content.dart';
import '../widgets/reader_progress_rail.dart';
import '../widgets/vertical_card_reader.dart';
import 'full_card_text_screen.dart';

typedef _TopicPage = ({DayCard topic, String? text, int index, int count});

/// Тема читается по чанкам, затем отдельная страница завершает её.
/// Следующая тема загружается только после свайпа за страницу завершения.
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
    final topic = _topicNumber(widget.currentTopic.id);
    if (topic > 1) ref.read(courseTopicByNumberProvider(topic - 1));
    if (_visible.text == null) {
      // Сохранение позиции могло успеть до записи завершения при закрытии ОС.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_resumeCompletion(topic));
      });
    }
  }

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
        (
          topic: card,
          text: chunks[index],
          index: index,
          count: chunks.length + 1,
        ),
      (topic: card, text: null, index: chunks.length, count: chunks.length + 1),
    ];
  }

  void _onPageChanged(int page) {
    setState(() => _index = page);
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
    if (visible.text == null) _queueCompletion(topic);
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
          // При движении назад открываем последний текстовый чанк,
          // а не страницу завершения: один свайп не засчитывает чужую тему.
          _index = oldIndex == 0
              ? _leading + added.length - 2
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
    } on Object {
      if (!mounted) return;
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
    // Тема могла сохраниться даже при неудачной записи активности дня.
    ref.invalidate(completedCourseTopicsProvider);
    ref.invalidate(courseTopicProvider);
    if (result is Success) ref.invalidate(dayProgressProvider);
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final brightness = Theme.of(context).brightness;
    final style = CardType.basics.styleFor(brightness);
    final visible = _visible;
    final card = visible.topic;
    final topic = _topicNumber(card.id);
    final completed = ref.watch(completedCourseTopicsProvider).value;
    return PopScope<void>(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_dismiss());
      },
      child: Scaffold(
        body: VerticalCardReader(
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
            if (item.text == null) {
              return _completionPage(item, colors, completed);
            }
            return CardContent(
              key: ValueKey('${item.topic.id}-${item.index}'),
              card: item.topic.copyWith(body: item.text!.trim(), title: null),
              showBadge: false,
              showSource: false,
              scrollable: false,
            );
          },
          header: AppPillBadge(
            label: 'Основы веры · Тема №$topic',
            background: style.tagBackground,
            foreground: style.tagForeground,
            letterSpacing: 0.2,
          ),
          leftRail: ReaderProgressRail(
            key: ValueKey(card.id),
            count: visible.count,
            currentIndex: visible.index,
            accent: style.accent,
          ),
          actions: _isBoundary || visible.text == null
              ? const SizedBox.shrink()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (visible.text!.length > CardContent.previewLength)
                      ReaderActionButton(
                        tooltip: 'Открыть полный текст',
                        onPressed: () => Navigator.of(context).push(
                          FullCardTextRoute(
                            card: card.copyWith(
                              body: visible.text!.trim(),
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
                        text: visible.text!.trim(),
                        source: card.source,
                        label: style.label,
                        savedAt: DateTime.fromMillisecondsSinceEpoch(0),
                      ),
                      iconSize: 28,
                      buttonSize: 56,
                    ),
                    AppShareButton(
                      text: '${card.body}\n\n— ${card.source}',
                      iconSize: 28,
                      buttonSize: 56,
                    ),
                  ],
                ),
          onClose: () => unawaited(_dismiss()),
          closeColor: colors.homeSubtitle,
        ),
      ),
    );
  }

  Widget _completionPage(
    _TopicPage page,
    AppColorsExtension colors,
    Set<int>? completed,
  ) {
    final topic = _topicNumber(page.topic.id);
    final failed = _completionErrors.contains(topic);
    final saving = _completing.contains(topic);
    final finished = completed?.length == courseTopicCount;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 70),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              failed
                  ? 'Не удалось сохранить прогресс'
                  : saving
                  ? 'Сохраняем прогресс…'
                  : finished
                  ? 'Курс пройден'
                  : 'Тема прочитана',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, color: colors.ink),
            ),
            const SizedBox(height: 20),
            Text(
              topic == courseTopicCount
                  ? 'Это последняя тема курса. Вы можете вернуться к предыдущим темам.'
                  : 'Авторы рекомендуют читать по одной теме в день. '
                        'Можно продолжить завтра или, если хочется читать дальше, '
                        'свайпнуть вверх к следующей теме.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, height: 1.5, color: colors.ink),
            ),
            if (failed)
              TextButton(
                onPressed: _isDismissing ? null : () => _queueCompletion(topic),
                child: const Text('Повторить сохранение'),
              ),
          ],
        ),
      ),
    );
  }
}

int _topicNumber(String id) {
  final match = RegExp(r'^basics-topic-(\d+)$').firstMatch(id);
  return int.tryParse(match?.group(1) ?? '') ?? 1;
}
