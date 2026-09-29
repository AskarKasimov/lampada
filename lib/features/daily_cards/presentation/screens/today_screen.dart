import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../../../core/format/date_key.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../day_story/presentation/screens/day_story_screen.dart';
import '../../../reading/presentation/providers/providers.dart';
import '../../../reminders/presentation/providers/providers.dart';
import '../../../reminders/presentation/screens/reminder_permission_screen.dart';
import '../../../shell/presentation/widgets/floating_nav_bar.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/entities/day_progress.dart';
import '../../domain/entities/today_cards.dart';
import '../providers/providers.dart';
import '../widgets/course_progress_header.dart';
import '../widgets/day_entry_row.dart';
import '../widgets/day_name_header.dart';
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

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedDateProvider);
    final progress = ref.watch(dayProgressProvider).value;
    final selectedPage = _pageMapper.pageForDate(selected);
    ref.watch(
      dayCardsProvider(dateKey(_pageMapper.dateForPage(selectedPage - 1))),
    );
    ref.watch(
      dayCardsProvider(dateKey(_pageMapper.dateForPage(selectedPage + 1))),
    );
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
                ref
                    .read(selectedDateProvider.notifier)
                    .select(_pageMapper.dateForPage(page));
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
    final cardsAsync = ref.watch(dayCardsProvider(key));
    final day = cardsAsync.value;
    final progress = ref.watch(dayProgressProvider).value;
    return _body(context, ref, date, key, cardsAsync, day, progress);
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    DateTime selected,
    String key,
    AsyncValue<TodayCards> cardsAsync,
    TodayCards? day,
    DayProgress? progress,
  ) {
    // Готовый день остаётся полезнее последней ошибки обновления.
    if (day != null && progress != null) {
      return _DayBlocks(date: selected, day: day, progress: progress);
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
            child: TodayOfflineView(
              date: selected,
              kind: kind,
              onRetry: () {
                ref.invalidate(dayCardsProvider(key));
                ref.invalidate(dayProgressProvider);
              },
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

/// Полоска недели и заголовок выбранного дня.
class _Header extends ConsumerWidget {
  const _Header({required this.selected, required this.progress});

  final DateTime selected;
  final DayProgress? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColorsExtension.of(context);
    final week = ref.watch(dayCardsProvider(dateKey(selected))).value?.week;

    return Padding(
      padding:
          AppSpacing.of(context).horizontal +
          const EdgeInsets.only(top: 6, bottom: 4),
      child: Column(
        children: [
          // Пустая строка сохраняет место; длинное название показываем целиком.
          Text(
            (week ?? '').toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.1,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          WeekStrip(
            selected: selected,
            today: DateTime.now(),
            litDays: progress?.visitedDays ?? const {},
            onSelect: (day) =>
                ref.read(selectedDateProvider.notifier).select(day),
          ),
        ],
      ),
    );
  }
}

class _DayBlocks extends ConsumerStatefulWidget {
  const _DayBlocks({
    required this.date,
    required this.day,
    required this.progress,
  });

  final DateTime date;
  final TodayCards day;
  final DayProgress progress;

  @override
  ConsumerState<_DayBlocks> createState() => _DayBlocksState();
}

class _DayBlocksState extends ConsumerState<_DayBlocks> {
  DateTime get date => widget.date;
  TodayCards get day => widget.day;
  DayProgress get progress => widget.progress;

  bool get _isToday => dateKey(date) == dateKey(DateTime.now());

  bool get _isFuture => dateKey(date).compareTo(dateKey(DateTime.now())) > 0;

  bool get _recordProgress => _isToday;

  // Будущий контент можно открыть заранее, но это не должно менять прогресс.
  bool get _recordRead => !_isFuture;

  List<DayCard> get _pages =>
      day.cards.where((c) => c.type != CardType.basics).toList()
        ..sort((a, b) => a.type.index.compareTo(b.type.index));

  Future<void> _openWisdom() async {
    final pages = _pages;
    final firstUnread = pages.indexWhere((card) => !_isRead(card));
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
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
  }

  /// Просит разрешение после закрытия контента, не на старте сессии.
  Future<void> _maybeAskReminders() async {
    if (!_recordProgress) return;
    await _maybeAskForReminders(context, ref);
  }

  Future<void> _openStory(
    BuildContext context,
    String title,
    String storyUrl,
  ) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => DayStoryScreen(title: title, storyUrl: storyUrl),
    ),
  );

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

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final pages = _pages;
    final blocks = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: FloatingNavInset.of(context) + 32),
      children: [
        if (day.hasName) ...[
          DayNameHeader(
            day: day,
            onTap: (day.title ?? '').isEmpty || day.storyUrl == null
                ? null
                : () => _openStory(context, day.title!, day.storyUrl!),
          ),
          const DayEntryDivider(),
        ],
        if (pages.isNotEmpty)
          DayEntryRow(
            label: 'ДЕНЬ',
            text: 'Мудрость дня',
            isUnread: pages.any((card) => !_isRead(card)),
            topSpacing: day.hasName ? 14 : 4,
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
        const DayEntryDivider(),
        const _CourseHomeSection(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: AppSpacing.of(context).horizontal,
            child: IconButton(
              tooltip: 'О курсе',
              color: colors.textSecondary,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PlansInfoScreen(),
                ),
              ),
              icon: const Icon(CupertinoIcons.info),
            ),
          ),
        ),
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
          )
        else
          Padding(
            padding: AppSpacing.of(context).horizontal,
            child: topic.isLoading
                ? Text(
                    'Загружаем «Основы веры»',
                    style: TextStyle(color: colors.homeSubtitle),
                  )
                : Column(
                    children: [
                      const Text('Не удалось загрузить «Основы веры»'),
                      TextButton(
                        onPressed: () => ref.invalidate(courseTopicProvider),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
          ),
      ],
    );
  }
}

Future<void> _maybeAskForReminders(BuildContext context, WidgetRef ref) async {
  final read = ref.read(dayProgressProvider).value?.readTypes ?? const {};
  if (read.isEmpty) return;

  // Прогресс сохраняется асинхронно, поэтому ожидаем провайдер, а не value.
  final settings = await ref.read(reminderSettingsProvider.future);
  if (settings.asked || !context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const ReminderPermissionScreen(),
    ),
  );
}
