import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../../../core/format/date_key.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../day_story/presentation/screens/day_story_screen.dart';
import '../../../reading/presentation/providers/providers.dart';
import '../../../reading/presentation/screens/reading_screen.dart';
import '../../../reminders/presentation/providers/providers.dart';
import '../../../reminders/presentation/screens/reminder_permission_screen.dart';
import '../../../shell/presentation/widgets/floating_nav_bar.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/entities/day_progress.dart';
import '../../domain/entities/today_cards.dart';
import '../providers/providers.dart';
import '../theme/card_type_style.dart';
import '../widgets/day_entry_row.dart';
import '../widgets/day_name_header.dart';
import '../widgets/today_offline_view.dart';
import '../widgets/week_strip.dart';
import 'card_viewer_screen.dart';

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

  // Автооткрытие относится к экрану, а не к странице календаря.
  bool _hasAutoOpened = false;

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

  void _markAutoOpened() {
    if (_hasAutoOpened) return;
    setState(() => _hasAutoOpened = true);
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
              itemBuilder: (context, page) => _TodayDayPage(
                date: _pageMapper.dateForPage(page),
                hasAutoOpened: _hasAutoOpened,
                onAutoOpened: _markAutoOpened,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayDayPage extends ConsumerWidget {
  const _TodayDayPage({
    required this.date,
    required this.hasAutoOpened,
    required this.onAutoOpened,
  });

  final DateTime date;
  final bool hasAutoOpened;
  final VoidCallback onAutoOpened;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDateProvider);
    final isSelected = dateKey(selected) == dateKey(date);
    // Исходящий день остаётся видимым до полного исчезновения при фэйде.
    return _SelectedDayContent(
      date: date,
      isSelected: isSelected,
      hasAutoOpened: hasAutoOpened,
      onAutoOpened: onAutoOpened,
    );
  }
}

class _SelectedDayContent extends ConsumerWidget {
  const _SelectedDayContent({
    required this.date,
    required this.isSelected,
    required this.hasAutoOpened,
    required this.onAutoOpened,
  });

  final DateTime date;
  final bool isSelected;
  final bool hasAutoOpened;
  final VoidCallback onAutoOpened;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = dateKey(date);
    final cardsAsync = ref.watch(dayCardsProvider(key));
    final day = cardsAsync.value;
    final progress = ref.watch(dayProgressProvider).value;
    final courseTopic = ref.watch(courseTopicProvider).value;
    return _body(
      context,
      ref,
      date,
      key,
      cardsAsync,
      day,
      progress,
      courseTopic,
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    DateTime selected,
    String key,
    AsyncValue<TodayCards> cardsAsync,
    TodayCards? day,
    DayProgress? progress,
    DayCard? courseTopic,
  ) {
    // Готовый день остаётся полезнее последней ошибки обновления.
    if (day != null && progress != null) {
      return _DayBlocks(
        date: selected,
        day: _withCourseTopic(selected, day, courseTopic),
        progress: progress,
        isSelected: isSelected,
        hasAutoOpened: hasAutoOpened,
        onAutoOpened: onAutoOpened,
      );
    }

    if (cardsAsync.hasError || progress == null && !cardsAsync.isLoading) {
      final kind = switch (cardsAsync.error) {
        AppFailure(kind: final k) => k,
        _ => FailureKind.unknown,
      };
      return TodayOfflineView(
        date: selected,
        kind: kind,
        onRetry: () {
          ref.invalidate(dayCardsProvider(key));
          ref.invalidate(dayProgressProvider);
        },
      );
    }

    return const SizedBox.shrink();
  }

  // Личный курс подменяет календарный placeholder только на сегодняшнем дне.
  TodayCards _withCourseTopic(DateTime date, TodayCards day, DayCard? topic) {
    if (dateKey(date) != dateKey(DateTime.now())) return day;
    if (topic == null) return day;

    final index = day.cards.indexWhere((c) => c.type == CardType.basics);
    if (index < 0) return day;
    return day.copyWith(cards: [...day.cards]..[index] = topic);
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
    required this.isSelected,
    required this.hasAutoOpened,
    required this.onAutoOpened,
  });

  final DateTime date;
  final TodayCards day;
  final DayProgress progress;
  final bool isSelected;
  final bool hasAutoOpened;
  final VoidCallback onAutoOpened;

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

  DayCard? get _reading =>
      day.cards.where((c) => c.type == CardType.reading).firstOrNull;

  List<DayCard> get _pages => day.cards
      .where((c) => c.type != CardType.reading && c.type != CardType.basics)
      .toList();

  // Личный курс открывается только из «Планов», по выбору пользователя.
  Iterable<DayCard> get _autoOpenCards =>
      day.cards.where((card) => card.type != CardType.basics);

  Future<void> _open(BuildContext context, WidgetRef ref, DayCard card) async {
    if (card.type == CardType.reading) {
      await _openReader(context, ref, card);
      return;
    }
    final pages = card.type == CardType.basics ? [card] : _pages;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CardViewerScreen(
          cards: pages,
          startIndex: pages.indexOf(card),
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

  Future<void> _openReader(
    BuildContext context,
    WidgetRef ref,
    DayCard card,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ReadingScreen(
          reference: card.reference!,
          date: date,
          recordProgress: _recordProgress,
          recordRead: _recordRead,
        ),
      ),
    );
    if (mounted) await _maybeAskReminders();
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

  bool _isRead(DayCard card) => _isToday
      ? progress.isRead(card.type)
      : progress.isReadOn(date, card.type);

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

  /// Открывает один первый непрочитанный раздел за вход в порядке [CardType].
  void _maybeAutoOpen() {
    if (widget.hasAutoOpened) return;
    if (!widget.isSelected) return;
    if (!_recordProgress) return;

    final unread = progress.firstUnreadOf(_autoOpenCards.map((c) => c.type));
    if (unread == null) return;

    final card = day.cards.firstWhere((c) => c.type == unread);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onAutoOpened();
      _open(context, ref, card);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    _maybeAutoOpen();
    final rest = _pages;
    final reading = _reading;

    if (reading == null && rest.isEmpty) {
      return Center(
        child: Text(
          'За этот день карточек нет',
          style: TextStyle(fontSize: 14, color: colors.homeSubtitle),
        ),
      );
    }

    final brightness = Theme.of(context).brightness;
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
        for (final card in rest)
          DayEntryRow(
            label: card.type.styleFor(brightness).shortLabel.toUpperCase(),
            text: card.body.replaceAll('\n', ' '),
            isUnread: !_isRead(card),
            labelColor: card.type.styleFor(brightness).accent,
            topSpacing: card == rest.first ? (day.hasName ? 14 : 4) : 0,
            bottomSpacing: reading != null && card == rest.last ? 14 : 0,
            onTap: () => _open(context, ref, card),
          ),
        if (reading != null) ...[
          if (rest.isNotEmpty) const DayEntryDivider(),
          DayEntryRow(
            label: 'ЕВАНГЕЛИЕ ДНЯ',
            text: reading.body,
            isUnread: !_isRead(reading),
            labelColor: CardType.reading.styleFor(brightness).accent,
            textSize: 27,
            maxLines: 1,
            topSpacing: rest.isNotEmpty || day.hasName ? 14 : 4,
            onTap: () => _openReader(context, ref, reading),
          ),
        ],
      ],
    );
    return RefreshIndicator(onRefresh: _refresh, child: blocks);
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
