import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_on_show.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/format/date_key.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../day_story/presentation/providers/providers.dart';
import '../../../day_story/presentation/screens/day_story_screen.dart';
import '../../../profile/presentation/providers/providers.dart';
import '../../../reading/presentation/providers/providers.dart';
import '../../../reminders/presentation/providers/providers.dart';
import '../../../reminders/presentation/screens/reminder_permission_screen.dart';
import '../../../shell/presentation/widgets/floating_nav_bar.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/entities/day_progress.dart';
import '../../domain/entities/day_section.dart';
import '../../domain/entities/today_cards.dart';
import '../providers/day_content_provider.dart';
import '../providers/providers.dart';
import '../widgets/course_progress_header.dart';
import '../widgets/day_memory_tile.dart';
import '../widgets/day_wisdom_tile.dart';
import '../widgets/streak_card.dart';
import '../widgets/today_offline_view.dart';
import '../widgets/week_strip.dart';
import 'course_reader_route.dart';
import 'day_wisdom_screen.dart';
import 'plans_info_screen.dart';

/// Дневная сессия и навигация по календарным дням.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

/// Преобразует страницы [PageView] в даты без арифметики длительностей.
class CalendarPageMapper {
  const CalendarPageMapper(this.initialDate, {this.initialPage = 10000});

  final DateTime initialDate;
  final int initialPage;

  DateTime dateForPage(int page) => DateTime(
    initialDate.year,
    initialDate.month,
    initialDate.day + page - initialPage,
  );

  int pageForDate(DateTime date) => initialPage + dayOffset(initialDate, date);

  static CalendarPageTransition transitionFor({
    required int currentPage,
    required int targetPage,
  }) => (currentPage - targetPage).abs() <= 1
      ? CalendarPageTransition.animate
      : CalendarPageTransition.fade;

  static int dayOffset(DateTime from, DateTime to) =>
      _dayNumber(to) - _dayNumber(from);

  static int _dayNumber(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}

enum CalendarPageTransition { animate, fade }

class _TodayScreenState extends ConsumerState<TodayScreen>
    with SingleTickerProviderStateMixin {
  late final CalendarPageMapper _pageMapper;
  late final PageController _pageController;
  Object? _pageAnimation;
  late final AnimationController _fadeController;
  final _prefetchedIconUrls = <String>{};

  @override
  void initState() {
    super.initState();
    _pageMapper = CalendarPageMapper(ref.read(selectedDateProvider));
    _pageController = PageController(initialPage: _pageMapper.initialPage);
    _fadeController = AnimationController(
      vsync: this,
      value: 1,
      duration: const Duration(milliseconds: 125),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _syncPage(DateTime date) async {
    if (!_pageController.hasClients) return;
    final target = _pageMapper.pageForDate(date);
    final page = _pageController.page;
    final current = page?.round();
    if (_pageAnimation == null && current == target) return;
    final animation = Object();
    _pageAnimation = animation;
    try {
      if (current != null &&
          CalendarPageMapper.transitionFor(
                currentPage: current,
                targetPage: target,
              ) ==
              CalendarPageTransition.fade) {
        await _fadeController.reverse().orCancel;
        // Новое нажатие отменяет прежнюю цель, даже пока экран гаснет.
        if (!mounted || !identical(_pageAnimation, animation)) return;
        _pageController.jumpToPage(target);
        // Показываем из пустоты только готовый материал или ошибку загрузки.
        await Future.wait([
          _waitForResult(dayCardsProvider(dateKey(date))),
          _waitForResult(dayProgressProvider),
        ]);
        if (!mounted || !identical(_pageAnimation, animation)) return;
        await _fadeController.forward().orCancel;
      } else {
        _fadeController.forward();
        await _pageController.animateToPage(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } on TickerCanceled {
      // Смена даты или закрытие экрана прерывает фэйд.
    } finally {
      if (identical(_pageAnimation, animation)) _pageAnimation = null;
    }
  }

  Future<void> _waitForResult<T>(
    ProviderListenable<AsyncValue<T>> provider,
  ) async {
    final ready = Completer<void>();
    final subscription = ref.listenManual(provider, (_, value) {
      // Ошибка уже доступна UI, даже если Riverpod планирует повтор запроса.
      if ((value.hasValue || value.hasError) && !ready.isCompleted) {
        ready.complete();
      }
    }, fireImmediately: true);
    try {
      await ready.future;
    } finally {
      subscription.close();
    }
  }

  /// Прогрев изображений остаётся в presentation: он требует контекст
  /// Flutter и использует тот же ImageCache, что плитка и обложка рассказа.
  void _precacheIcon(String? iconUrl) {
    if (iconUrl == null || !_prefetchedIconUrls.add(iconUrl)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        precacheImage(
          NetworkImage(iconUrl),
          context,
          // Ошибка иконы не блокирует текст; следующая перестройка
          // позволяет повторить загрузку изображения.
          onError: (_, _) => _prefetchedIconUrls.remove(iconUrl),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedDateProvider);
    final progress = ref.watch(dayProgressProvider).value;
    final selectedPage = _pageMapper.pageForDate(selected);
    for (var offset = -1; offset <= 1; offset++) {
      final date = _pageMapper.dateForPage(selectedPage + offset);
      final content = ref.watch(dayContentProvider(dateKey(date)));
      _precacheIcon(content.iconUrl);
    }
    ref.listen<DateTime>(selectedDateProvider, (_, selected) {
      _syncPage(selected);
    });

    return Column(
      children: [
        _Header(selected: selected, progress: progress),
        Expanded(
          child: FadeTransition(
            opacity: _fadeController,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                // При выборе даты промежуточные страницы не меняют календарь.
                if (_pageAnimation != null) return;
                final day = _pageMapper.dateForPage(page);
                _logDateSelected(ref, day, DateSelectSource.swipe);
                ref.read(selectedDateProvider.notifier).select(day);
              },
              itemBuilder: (context, page) =>
                  _TodayDayPage(date: _pageMapper.dateForPage(page)),
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayDayPage extends ConsumerWidget {
  const _TodayDayPage({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Исходящий день остаётся видимым до полного исчезновения при фэйде.
    return _SelectedDayContent(date: date);
  }
}

class _SelectedDayContent extends ConsumerWidget {
  const _SelectedDayContent({required this.date});

  final DateTime date;

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
    DateTime selected,
    String key,
    DayContentState content,
    DayProgress? progress,
  ) {
    final cardsAsync = content.cards;
    final day = cardsAsync.value;
    // Готовый день остаётся полезнее последней ошибки обновления.
    if (day != null && progress != null) {
      return _DayBlocks(date: selected, content: content, progress: progress);
    }

    if (cardsAsync.hasError || progress == null && !cardsAsync.isLoading) {
      final kind = switch (cardsAsync.error) {
        AppFailure(kind: final k) => k,
        _ => FailureKind.unknown,
      };
      return ListView(
        padding: EdgeInsets.only(bottom: FloatingNavInset.of(context) + 32),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: AnalyticsOnShow(
              event: AnalyticsEvent.contentLoadFailed(
                content: LoadedContent.day,
                kind: kind.name,
              ),
              child: TodayOfflineView(
                date: selected,
                kind: kind,
                onRetry: () {
                  ref
                      .read(analyticsProvider)
                      .log(
                        AnalyticsEvent.contentRetryTapped(LoadedContent.day),
                      );
                  ref.invalidate(dayCardsProvider(key));
                  ref.invalidate(dayProgressProvider);
                },
              ),
            ),
          ),
          const _CourseHomeSection(),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.only(bottom: FloatingNavInset.of(context) + 32),
      children: const [_CourseHomeSection()],
    );
  }
}

/// Полоска недели над выбранным днём.
class _Header extends ConsumerWidget {
  const _Header({required this.selected, required this.progress});

  final DateTime selected;
  final DayProgress? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Строку седмицы над полоской убрали: она почти ничего не сообщала,
    // а шапку перегружала.
    return Padding(
      padding:
          AppSpacing.of(context).horizontal +
          const EdgeInsets.only(top: 6, bottom: 4),
      child: Column(
        children: [
          WeekStrip(
            selected: selected,
            today: DateTime.now(),
            litDays: progress?.visitedDays ?? const {},
            onSelect: (day, source) {
              _logDateSelected(ref, day, source);
              ref.read(selectedDateProvider.notifier).select(day);
            },
          ),
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
  });

  final DateTime date;
  final DayContentState content;
  final DayProgress progress;

  @override
  ConsumerState<_DayBlocks> createState() => _DayBlocksState();
}

class _DayBlocksState extends ConsumerState<_DayBlocks> {
  DateTime get date => widget.date;
  TodayCards get day => widget.content.cards.requireValue;
  DayProgress get progress => widget.progress;

  bool get _isToday => dateKey(date) == dateKey(DateTime.now());

  bool get _isFuture => dateKey(date).compareTo(dateKey(DateTime.now())) > 0;

  bool get _recordProgress => _isToday;

  // Будущий контент можно открыть заранее, но это не должно менять прогресс.
  bool get _recordRead => !_isFuture;

  List<DayCard> get _pages =>
      day.cards.where((c) => c.type != CardType.basics).toList()
        ..sort((a, b) => a.type.index.compareTo(b.type.index));

  Future<void> _openWisdom({OpenSource source = OpenSource.tile}) async {
    if (widget.content.readingIsLoading) return;
    final pages = _pages;
    final firstUnread = pages.indexWhere((card) => !_isRead(card));
    final completedBefore = _wisdomEverCompleted;
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
    // Открывается внутри вкладки, а не модально: навбар остаётся виден.
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DayWisdomScreen(
          cards: pages,
          startIndex: firstUnread < 0 ? 0 : firstUnread,
          date: date,
          recordProgress: _recordProgress,
          recordRead: _recordRead,
        ),
      ),
    );
    if (mounted) await _maybeAskReminders();
    if (mounted && !completedBefore && _wisdomEverCompleted) {
      ref
          .read(analyticsProvider)
          .log(AnalyticsEvent.reviewRequested(ReviewTrigger.firstCompletion));
      await ref.read(profileActionsServiceProvider).requestReview();
    }
  }

  /// Оценку просим один раз: когда юзер впервые прошёл «Мудрость дня» и ушёл
  /// с итога. Пока он смотрит на лампаду, системный диалог её не перекрывает.
  bool get _wisdomEverCompleted =>
      ref.read(dayProgressProvider).value?.wisdomCompletedDays.isNotEmpty ??
      false;

  /// Просит разрешение после закрытия контента, не на старте сессии.
  Future<void> _maybeAskReminders() async {
    if (!_recordProgress) return;
    await _maybeAskForReminders(context, ref);
  }

  /// Открытие рассказа считается прочтением: напоминание о святом звало
  /// именно открыть его.
  Future<void> _openStory(
    BuildContext context,
    String title,
    String storyUrl, {
    OpenSource source = OpenSource.tile,
  }) {
    ref
        .read(analyticsProvider)
        .log(
          AnalyticsEvent.storyOpened(
            source: source,
            dayOffset: dayOffset(date),
            hasIcon: widget.content.iconUrl != null,
          ),
        );
    unawaited(ref.read(readStoryDaysProvider.notifier).markRead(date));
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => DayStoryScreen(title: title, storyUrl: storyUrl),
      ),
    );
  }

  bool _isRead(DayCard card) => progress.isReadOn(date, card.type);

  /// Обновляет кэш, не скрывая прежний контент при ошибке.
  Future<void> _refresh() async {
    final courseRefresh = ref.read(getCourseTopicProvider)(forceRefresh: true);
    final result = await ref.read(getTodayCardsProvider)(
      date,
      forceRefresh: true,
    );
    if (result is Success<TodayCards>) {
      ref.invalidate(dayCardsProvider(dateKey(date)));
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
    if (courseResult is Success) {
      ref.invalidate(courseTopicProvider);
    }
  }

  /// Открывает раздел по просьбе приветствия или напоминания, когда
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
        case DaySection.story when _hasStory:
          _openStory(context, day.title!, day.storyUrl!, source: source);
        default:
          break;
      }
    });
  }

  bool get _hasStory => (day.title ?? '').isNotEmpty && day.storyUrl != null;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final pages = _pages;
    _openRequestedSection(pages);
    final blocks = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: FloatingNavInset.of(context) + 32),
      children: [
        if ((day.title ?? '').isNotEmpty)
          DayMemoryTile(
            day: day,
            iconUrl: widget.content.iconUrl,
            onTap: () => _openStory(context, day.title!, day.storyUrl!),
          )
        else if (day.isFast)
          // Без памяти дня пост всё равно отмечаем, но без плитки.
          Padding(
            padding:
                AppSpacing.of(context).horizontal +
                const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              'Постный день',
              style: TextStyle(fontSize: 13, color: colors.accent),
            ),
          ),
        if (pages.isNotEmpty)
          DayWisdomTile(
            isLoading: widget.content.readingIsLoading,
            isUnread: pages.any((card) => !_isRead(card)),
            onTap: _openWisdom,
          ),
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
        const _CourseHomeSection(),
        // Серия относится к сегодняшнему дню, а не к выбранному в полоске.
        if (ref.watch(dayProgressProvider).value case final progress?)
          StreakCard(progress: progress, today: DateTime.now()),
      ],
    );
    return RefreshIndicator(onRefresh: _refresh, child: blocks);
  }
}

/// Курс не зависит от выбранного дня и остаётся доступным при ошибке дня.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (topic.value case final currentTopic?)
          CourseProgressHeader(
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
            onInfo: () {
              ref
                  .read(analyticsProvider)
                  .log(
                    AnalyticsEvent.courseInfoOpened(CourseInfoScreen.plansInfo),
                  );
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PlansInfoScreen(),
                ),
              );
            },
          )
        else
          Padding(
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
          ),
      ],
    );
  }
}

void _logDateSelected(WidgetRef ref, DateTime day, DateSelectSource source) =>
    ref
        .read(analyticsProvider)
        .log(
          AnalyticsEvent.dateSelected(
            source: source,
            dayOffset: dayOffset(day),
          ),
        );

Future<void> _maybeAskForReminders(BuildContext context, WidgetRef ref) async {
  final read = ref.read(dayProgressProvider).value?.readTypes ?? const {};
  if (read.isEmpty) return;

  // Прогресс сохраняется асинхронно, поэтому ожидаем провайдер, а не value.
  final settings = await ref.read(reminderSettingsProvider.future);
  if (settings.asked || !context.mounted) return;

  // Вопрос о разрешении накрывает весь шелл, вместе с навбаром.
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) =>
          const ReminderPermissionScreen(trigger: ReminderPromptTrigger.wisdom),
    ),
  );
}
