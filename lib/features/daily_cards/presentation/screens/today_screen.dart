import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_on_show.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/analytics/screen_tracker.dart';
import '../../../../core/format/date_key.dart';
import '../../../../core/format/russian_date.dart';
import '../../../../core/navigation/bottom_up_modal_route.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../bible/presentation/providers/providers.dart'
    show verseOfDayProvider;
import '../../../bible/presentation/widgets/verse_of_day_card.dart';
import '../../../day_story/presentation/providers/providers.dart';
import '../../../day_story/presentation/screens/day_story_screen.dart';
import '../../../reading/presentation/providers/providers.dart';
import '../../../shell/presentation/services/after_reading_prompts.dart';
import '../../../shell/presentation/widgets/floating_nav_bar.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/entities/day_memory.dart';
import '../../domain/entities/day_progress.dart';
import '../../domain/entities/day_section.dart';
import '../../domain/entities/today_cards.dart';
import '../providers/day_content_provider.dart';
import '../providers/providers.dart';
import '../widgets/course_progress_header.dart';
import '../widgets/day_memory_tile.dart';
import '../widgets/day_wisdom_tile.dart';
import '../widgets/home_header.dart';
import '../widgets/home_section_header.dart';
import '../widgets/streak_sheet.dart';
import '../widgets/today_offline_view.dart';
import 'course_reader_route.dart';
import 'day_wisdom_screen.dart';
import 'lamp_lit_screen.dart';

/// Дневная сессия: всегда сегодняшний день, без выбора даты.
///
/// Список уходит под закреплённую шапку: она матовая и растворяется книзу,
/// поэтому контент скрывается под ней мягко, без чёткой границы. Высоту
/// шапки меряем, чтобы в покое список начинался сразу под ней.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  double _headerHeight = 0;

  @override
  Widget build(BuildContext context) =>
      AnalyticsScreen(screen: AppScreen.home, child: _buildScreen(context));

  Widget _buildScreen(BuildContext context) {
    // «Сегодня» берём при каждой перестройке: при возврате в приложение
    // прогресс перечитывается, и после полуночи экран сам переходит на
    // новый день.
    final now = DateTime.now();
    final progress = ref.watch(dayProgressProvider).value;
    return Stack(
      children: [
        Positioned.fill(
          child: _DayContent(date: now, topInset: _headerHeight),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _HeightReporter(
            onHeight: (height) {
              if (height != _headerHeight) {
                setState(() => _headerHeight = height);
              }
            },
            child: FrostedHomeHeader(
              child: HomeHeader(
                now: now,
                streak: progress?.streakOn(now),
                onStreakTap: () => showStreakSheet(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Сообщает высоту ребёнка после раскладки. Шапка меняет высоту с
/// системным масштабом текста, а список должен отступать ровно на неё.
class _HeightReporter extends SingleChildRenderObjectWidget {
  const _HeightReporter({required this.onHeight, required super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHeightReporter(onHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHeightReporter renderObject,
  ) => renderObject.onHeight = onHeight;
}

Future<void> _refreshDay(WidgetRef ref, DateTime date) async {
  final key = dateKey(date);
  ref.invalidate(verseOfDayProvider(key));
  final courseRefresh = ref.read(getCourseTopicProvider)(forceRefresh: true);
  final result = await ref.read(getTodayCardsProvider)(
    date,
    forceRefresh: true,
  );
  if (result is Success<TodayCards>) {
    ref.invalidate(dayCardsProvider(key));
    final reading = result.value.cards
        .where((card) => card.type == CardType.reading)
        .firstOrNull;
    if (reading?.reference case final reference?) {
      final readingRefresh = await ref.read(getDailyReadingProvider)(
        reference,
        forceRefresh: true,
      );
      if (readingRefresh is Success) {
        ref.invalidate(dailyReadingProvider(reference));
      }
    }
  }
  final courseResult = await courseRefresh;
  if (courseResult is Success) ref.invalidate(courseTopicProvider);
}

class _RenderHeightReporter extends RenderProxyBox {
  _RenderHeightReporter(this.onHeight);

  ValueChanged<double> onHeight;
  double? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (height == _reported) return;
    _reported = height;
    // Менять состояние во время раскладки нельзя: сообщаем после кадра.
    WidgetsBinding.instance.addPostFrameCallback((_) => onHeight(height));
  }
}

class _DayContent extends ConsumerWidget {
  const _DayContent({required this.date, required this.topInset});

  final DateTime date;

  /// Высота шапки над списком.
  final double topInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = dateKey(date);
    final content = ref.watch(dayContentProvider(key));
    final progress = ref.watch(dayProgressProvider).value;
    return _body(context, ref, date, key, content, progress);
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    String key,
    DayContentState content,
    DayProgress? progress,
  ) {
    final cardsAsync = content.cards;
    final day = cardsAsync.value;
    // Готовый день остаётся полезнее последней ошибки обновления.
    if (day != null && progress != null) {
      return _DayBlocks(
        date: date,
        content: content,
        progress: progress,
        topInset: topInset,
      );
    }

    if (cardsAsync.hasError || progress == null && !cardsAsync.isLoading) {
      final kind = switch (cardsAsync.error) {
        AppFailure(kind: final k) => k,
        _ => FailureKind.unknown,
      };
      return RefreshIndicator(
        edgeOffset: topInset,
        onRefresh: () => _refreshDay(ref, date),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: topInset,
            bottom: FloatingNavInset.of(context) + 32,
          ),
          children: [
            // Стих дня не зависит от материалов дня и виден и без них.
            _dayHeader(date),
            VerseOfDaySection(date: date),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: AnalyticsOnShow(
                event: AnalyticsEvent.contentLoadFailed(
                  content: LoadedContent.day,
                  kind: kind.name,
                ),
                child: TodayOfflineView(
                  date: date,
                  kind: kind,
                  onRetry: () {
                    ref
                        .read(analyticsProvider)
                        .log(
                          AnalyticsEvent.contentRetryTapped(LoadedContent.day),
                        );
                    unawaited(_refreshDay(ref, date));
                    ref.invalidate(dayCardsProvider(key));
                    ref.invalidate(dayProgressProvider);
                  },
                ),
              ),
            ),
            _plansHeader,
            const _CourseHomeSection(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      edgeOffset: topInset,
      onRefresh: () => _refreshDay(ref, date),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          top: topInset,
          bottom: FloatingNavInset.of(context) + 32,
        ),
        children: [
          _dayHeader(date),
          VerseOfDaySection(date: date),
          _plansHeader,
          const _CourseHomeSection(),
        ],
      ),
    );
  }
}

class _DayBlocks extends ConsumerStatefulWidget {
  const _DayBlocks({
    required this.date,
    required this.content,
    required this.progress,
    required this.topInset,
  });

  final DateTime date;
  final DayContentState content;
  final DayProgress progress;
  final double topInset;

  @override
  ConsumerState<_DayBlocks> createState() => _DayBlocksState();
}

class _DayBlocksState extends ConsumerState<_DayBlocks> {
  DateTime get date => widget.date;
  TodayCards get day => widget.content.cards.requireValue;
  DayProgress get progress => widget.progress;

  /// Главная всегда показывает сегодня, но экран, открытый до полуночи,
  /// не должен засчитывать серию за уже прошедший день.
  bool get _isToday => dateKey(date) == dateKey(DateTime.now());

  bool get _recordProgress => _isToday;

  List<DayCard> get _pages =>
      day.cards.where((c) => c.type != CardType.basics).toList()
        ..sort((a, b) => a.type.index.compareTo(b.type.index));

  /// Плитка «Мудрости дня» прыгает, пока новичок её ни разу не открыл.
  bool _hintWisdom = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadWisdomHint());
  }

  Future<void> _loadWisdomHint() async {
    final hint = await ref.read(shouldHintDayWisdomProvider)(progress);
    if (mounted && hint) setState(() => _hintWisdom = true);
  }

  Future<void> _openWisdom({OpenSource source = OpenSource.tile}) async {
    if (widget.content.readingIsLoading) return;
    if (_hintWisdom) {
      setState(() => _hintWisdom = false);
      unawaited(ref.read(wisdomHintRepositoryProvider).markWisdomOpened());
    }
    final pages = _pages;
    final firstUnread = pages.indexWhere((card) => !_isRead(card));
    ref
        .read(analyticsProvider)
        .log(
          AnalyticsEvent.wisdomOpened(
            source: source,
            dayOffset: dayOffset(date),
            cardsTotal: pages.length,
            resumed: firstUnread > 0,
            alreadyCompleted: progress.isWisdomCompletedOn(date),
          ),
        );
    // Выезжает снизу, как рассказ «Памяти дня», но в навигаторе вкладки, а
    // не корневом: навбар остаётся виден.
    await Navigator.of(context).push(
      BottomUpModalRoute<void>(
        builder: (_) => DayWisdomScreen(
          cards: pages,
          startIndex: firstUnread < 0 ? 0 : firstUnread,
          date: date,
          recordProgress: _recordProgress,
          recordRead: true,
        ),
      ),
    );
    // Итог «Мудрости» лежит внутри листалки: запросы идут после её закрытия
    // и не перекрывают лампаду.
    if (mounted) {
      await askAfterReading(context, ReminderPromptTrigger.wisdom);
    }
  }

  /// Святой дня считается прочитанным после последней страницы рассказа:
  /// вернувшись на главную, юзер видит на плитке следующего. Из рассказа
  /// можно перейти к любому святому дня, поэтому ему передаём их всех.
  /// Свайп за последнюю страницу зажигает «Лампадку», если день всё ещё
  /// сегодняшний, и первое зажжение за день показывает итог вместо главной.
  Future<void> _openStory(
    BuildContext context,
    DayMemory memory, {
    OpenSource source = OpenSource.tile,
  }) async {
    ref
        .read(analyticsProvider)
        .log(
          AnalyticsEvent.storyOpened(
            source: source,
            dayOffset: dayOffset(date),
            hasIcon: widget.content.iconUrl != null,
          ),
        );
    Route<void>? lampRoute;
    await Navigator.of(context).push(
      BottomUpModalRoute<void>(
        builder: (_) => DayStoryScreen(
          title: memory.title,
          storyUrl: memory.storyUrl,
          memories: day.memories,
          readUrls:
              ref.read(storyProgressProvider).value?.readOn(date) ?? const {},
          onCompleted: (storyUrl) => unawaited(
            ref.read(storyProgressProvider.notifier).markRead(date, storyUrl),
          ),
          onFinished: () async {
            final lamp = await ref
                .read(dayProgressProvider.notifier)
                .lightLamp(LampSource.story, contentDate: date);
            if (lamp == null || !lamp.litNow) return null;
            return lampRoute = BottomUpModalRoute<void>(
              builder: (_) => LampLitScreen(
                before: lamp.before,
                title: 'Память дня прочитана',
                canContinue: false,
              ),
            );
          },
          lampPending: _isToday && !progress.isLit(DateTime.now()),
        ),
      ),
    );
    // Итог лампады заменяет рассказ: запросы ждут, пока закроют и его.
    await lampRoute?.popped;
    if (context.mounted) {
      await askAfterReading(context, ReminderPromptTrigger.story);
    }
  }

  bool _isRead(DayCard card) => progress.isReadOn(date, card.type);

  /// Обновляет кэш, не скрывая прежний контент при ошибке.
  /// Открывает раздел по просьбе напоминания, когда
  /// сегодняшний день загружен. «Мудрость» ждёт и Евангелие, как и тап по
  /// плитке. Если раздела у дня нет, просьбу просто снимаем.
  void _openRequestedSection(List<DayCard> pages) {
    if (!_isToday) return;
    final section = ref.watch(openDaySectionRequestProvider)?.section;
    if (section == DaySection.wisdom && widget.content.readingIsLoading) {
      return;
    }
    if (section != DaySection.wisdom && section != DaySection.story) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final origin = ref
          .read(openDaySectionRequestProvider.notifier)
          .consume(section!);
      if (origin == null) return;
      final source = OpenSource.values.byName(origin.name);
      switch (section) {
        case DaySection.wisdom when pages.isNotEmpty:
          _openWisdom(source: source);
        case DaySection.story when _memory != null:
          _openStory(context, _memory!.memory, source: source);
        default:
          break;
      }
    });
  }

  ({DayMemory memory, bool isRead})? get _memory => widget.content.memory;

  /// Память и «Мудрость дня» в один ряд, двумя столбцами одной высоты:
  /// главное на плитках иллюстрации. Если плитка одна, она во всю ширину.
  Widget _dayTiles(BuildContext context, List<DayCard> pages) {
    final memory = _memory;
    final tiles = [
      // Память без своей страницы рассказа не открывает, но день называет.
      if (memory != null)
        DayMemoryTile(
          title: memory.memory.title,
          iconUrl: widget.content.iconUrl,
          isRead: memory.isRead,
          onTap: () => _openStory(context, memory.memory),
        )
      else if (day.title case final title? when title.isNotEmpty)
        DayMemoryTile(title: title),
      if (pages.isNotEmpty)
        DayWisdomTile(
          isLoading: widget.content.readingIsLoading,
          isUnread: pages.any((card) => !_isRead(card)),
          pictureUrl: day.pictureUrl,
          hop: _hintWisdom,
          onTap: _openWisdom,
        ),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding:
          AppSpacing.of(context).horizontal +
          const EdgeInsets.symmetric(vertical: 6),
      // Крупный текст может сделать одну плитку выше: соседняя тянется
      // следом, чтобы ряд оставался ровным.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, tile) in tiles.indexed) ...[
              if (index > 0) const SizedBox(width: _tileGap),
              Expanded(child: tile),
            ],
          ],
        ),
      ),
    );
  }

  static const _tileGap = 12.0;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final pages = _pages;
    _openRequestedSection(pages);
    final blocks = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: widget.topInset,
        bottom: FloatingNavInset.of(context) + 32,
      ),
      children: [
        _dayHeader(date, isFast: day.isFast),
        VerseOfDaySection(date: date),
        _dayTiles(context, pages),
        if (pages.isEmpty)
          Padding(
            padding:
                AppSpacing.of(context).horizontal +
                const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'За этот день карточек нет',
              style: TextStyle(fontSize: 14, color: colors.homeSubtitle),
            ),
          ),
        _plansHeader,
        const _CourseHomeSection(),
      ],
    );
    return RefreshIndicator(
      // Индикатор выезжает из-под шапки, а не прячется за ней.
      edgeOffset: widget.topInset,
      onRefresh: () => _refreshDay(ref, date),
      child: blocks,
    );
  }
}

/// Курс не зависит от дня и остаётся доступным при ошибке загрузки дня.
class _CourseHomeSection extends ConsumerWidget {
  const _CourseHomeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topic = ref.watch(courseTopicProvider);
    final colors = AppColorsExtension.of(context);
    // Курс не зависит от дня, поэтому просьбу из напоминания о курсе
    // исполняет сама секция, как только тема загружена.
    if (topic.hasValue &&
        ref.watch(openDaySectionRequestProvider)?.section ==
            DaySection.course) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final origin = ref
            .read(openDaySectionRequestProvider.notifier)
            .consume(DaySection.course);
        if (origin != null && topic.value != null) {
          openCourseReader(
            context,
            ref,
            source: OpenSource.values.byName(origin.name),
          );
        }
      });
    }
    if (topic.value case final currentTopic?) {
      return CourseProgressHeader(
        topic: currentTopic,
        isUnread:
            !(ref
                    .watch(dayProgressProvider)
                    .value
                    ?.isReadOn(DateTime.now(), CardType.basics) ??
                false),
        completedTopicCount: ref
            .watch(completedCourseTopicsProvider)
            .value
            ?.length,
        onTap: () => openCourseReader(context, ref),
      );
    }
    return Padding(
      padding: AppSpacing.of(context).horizontal,
      child: topic.isLoading
          ? Text(
              'Загружаем «Основы веры»',
              style: TextStyle(color: colors.homeSubtitle),
            )
          : AnalyticsOnShow(
              event: AnalyticsEvent.contentLoadFailed(
                content: LoadedContent.courseTopic,
                kind: failureKindOf(topic.error),
              ),
              child: Column(
                children: [
                  const Text('Не удалось загрузить «Основы веры»'),
                  TextButton(
                    onPressed: () {
                      ref
                          .read(analyticsProvider)
                          .log(
                            AnalyticsEvent.contentRetryTapped(
                              LoadedContent.courseTopic,
                            ),
                          );
                      ref.invalidate(courseTopicProvider);
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Раздел того, что меняется каждый день: стих, память и «Мудрость дня».
/// Называется сегодняшней датой; пост относится ко всему дню и подписан
/// справа от неё, а не на плитке.
Widget _dayHeader(DateTime date, {bool isFast = false}) => HomeSectionHeader(
  title: russianDayMonth(date),
  caption: isFast ? 'Постный день' : null,
  first: true,
);

/// Раздел планов без привязки к дню: курс и будущие планы чтения.
const _plansHeader = HomeSectionHeader(title: 'Планы');
