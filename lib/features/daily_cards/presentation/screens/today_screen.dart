import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/date_key.dart';
import '../../../../core/format/russian_date.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_loading_view.dart';
import '../../../reading/presentation/screens/reading_screen.dart';
import '../../../shell/presentation/widgets/floating_nav_bar.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/entities/day_progress.dart';
import '../../domain/entities/today_cards.dart';
import '../providers/providers.dart';
import '../widgets/basics_course_link.dart';
import '../widgets/basics_hero_block.dart';
import '../widgets/day_card_block.dart';
import '../widgets/reading_hero_block.dart';
import '../widgets/today_offline_view.dart';
import '../widgets/week_strip.dart';
import 'card_viewer_screen.dart';
import 'course_reader_screen.dart';

const _readerOpenDelay = Duration(milliseconds: 300);

/// Вкладка «Сегодня»: полоска недели и блоки выбранного дня.
///
/// Календарь отдельной вкладкой не живёт — неделя сверху закрывает навигацию
/// по датам (FR-018, FR-021). Сам контент открывается полноэкранно поверх
/// шелла: под таб-баром «одна мысль на экране» из §6 не получается.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

/// Сопоставляет страницы [PageView] с календарными днями без зависимости от
/// длины суток в локальном часовом поясе.
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
      : CalendarPageTransition.jump;

  static int dayOffset(DateTime from, DateTime to) =>
      _dayNumber(to) - _dayNumber(from);

  static int _dayNumber(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}

enum CalendarPageTransition { animate, jump }

class _TodayScreenState extends ConsumerState<TodayScreen> {
  late final CalendarPageMapper _pageMapper;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageMapper = CalendarPageMapper(ref.read(selectedDateProvider));
    _pageController = PageController(initialPage: _pageMapper.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncPage(DateTime date) {
    if (!_pageController.hasClients) return;
    final target = _pageMapper.pageForDate(date);
    final current = _pageController.page?.round();
    if (current == target) return;
    if (current == null ||
        CalendarPageMapper.transitionFor(
              currentPage: current,
              targetPage: target,
            ) ==
            CalendarPageTransition.jump) {
      _pageController.jumpToPage(target);
      return;
    }
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
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
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) => ref
                .read(selectedDateProvider.notifier)
                .select(_pageMapper.dateForPage(page)),
            itemBuilder: (context, page) =>
                _TodayDayPage(date: _pageMapper.dateForPage(page)),
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
    final selected = ref.watch(selectedDateProvider);
    final isSelected = dateKey(selected) == dateKey(date);
    final isNeighbour = CalendarPageMapper.dayOffset(selected, date).abs() == 1;
    return isSelected || isNeighbour
        ? _SelectedDayContent(date: date, isSelected: isSelected)
        : const BrandLoadingView();
  }
}

class _SelectedDayContent extends ConsumerWidget {
  const _SelectedDayContent({required this.date, required this.isSelected});

  final DateTime date;
  final bool isSelected;

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
    // Контент важнее ошибки: если карточки на руках есть, показываем их,
    // даже когда последнее обновление упало.
    if (day != null && progress != null) {
      return _DayBlocks(
        date: selected,
        day: _withCourseTopic(selected, day, courseTopic),
        progress: progress,
        isSelected: isSelected,
        courseTopic: courseTopic,
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

    return const BrandLoadingView();
  }

  /// Подменяет «Основы» дня на текущую тему курса.
  ///
  /// Только для сегодняшней даты: курс — это личный прогресс. Если тема не
  /// доехала, скрываем календарные «Основы», чтобы не выдать их за курс.
  TodayCards _withCourseTopic(DateTime date, TodayCards day, DayCard? topic) {
    if (dateKey(date) != dateKey(DateTime.now())) return day;
    if (topic == null) {
      return day.copyWith(
        cards: day.cards.where((c) => c.type != CardType.basics).toList(),
      );
    }

    final index = day.cards.indexWhere((c) => c.type == CardType.basics);
    if (index < 0) return day;
    return day.copyWith(cards: [...day.cards]..[index] = topic);
  }
}

/// Полоска недели и подпись даты. «Лампадка» видна только здесь (FR-019):
/// на самих карточках она читалась бы счётчиком, что запрещает FR-020.
class _Header extends ConsumerWidget {
  const _Header({required this.selected, required this.progress});

  final DateTime selected;
  final DayProgress? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColorsExtension.of(context);
    final today = DateTime.now();
    final isToday = dateKey(selected) == dateKey(today);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        children: [
          WeekStrip(
            selected: selected,
            today: today,
            litDays: progress?.visitedDays ?? const {},
            onSelect: (day) =>
                ref.read(selectedDateProvider.notifier).select(day),
          ),
          const SizedBox(height: 10),
          Text(
            isToday ? 'Сегодня' : russianDayMonth(selected),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.9,
              color: colors.todayLabel,
            ),
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
    required this.courseTopic,
  });

  final DateTime date;
  final TodayCards day;
  final DayProgress progress;
  final bool isSelected;
  final DayCard? courseTopic;

  @override
  ConsumerState<_DayBlocks> createState() => _DayBlocksState();
}

class _DayBlocksState extends ConsumerState<_DayBlocks> {
  /// Просмотрщик уже открывался автоматически в этот запуск. Без флага
  /// возврат из него открывал бы его снова: прогресс пишется асинхронно,
  /// и на один кадр непрочитанная карточка ещё выглядит непрочитанной.
  bool _autoOpened = false;

  DateTime get date => widget.date;
  TodayCards get day => widget.day;
  DayProgress get progress => widget.progress;

  bool get _isToday => dateKey(date) == dateKey(DateTime.now());

  bool get _isFuture => dateKey(date).compareTo(dateKey(DateTime.now())) > 0;

  bool get _recordProgress => _isToday;

  /// Карточка чтения своей страницы в просмотрщике не имеет — экран с одной
  /// ссылкой и кнопкой «Читать» был лишним шагом.
  DayCard? get _reading =>
      day.cards.where((c) => c.type == CardType.reading).firstOrNull;

  /// Личный курс показываем только на сегодняшнем дне: на остальных датах
  /// календарная тема «Основ» не должна притворяться продолжением курса.
  DayCard? get _basics => _isToday
      ? day.cards.where((c) => c.type == CardType.basics).firstOrNull
      : null;

  DayCard? get _courseLink => _isToday ? null : widget.courseTopic;

  List<DayCard> get _pages => day.cards
      .where((c) => c.type != CardType.reading && c.type != CardType.basics)
      .toList();

  Future<void> _open(BuildContext context, WidgetRef ref, DayCard card) async {
    if (card.type == CardType.reading) {
      _openReader(context, ref, card);
      return;
    }
    if (card.type == CardType.basics) {
      _openCourse(context, card);
      return;
    }
    final pages = _pages;
    final reading = await Navigator.of(context).push<DayCard>(
      MaterialPageRoute<DayCard>(
        fullscreenDialog: true,
        builder: (_) => CardViewerScreen(
          cards: pages,
          startIndex: pages.indexOf(card),
          recordProgress: _recordProgress,
          reading: _reading,
        ),
      ),
    );
    if (!context.mounted || reading == null) return;
    await Future<void>.delayed(_readerOpenDelay);
    if (!context.mounted) return;
    _openReader(context, ref, reading);
  }

  void _openReader(BuildContext context, WidgetRef ref, DayCard card) {
    if (_recordProgress) {
      ref.read(dayProgressProvider.notifier).markRead(card.type);
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReadingScreen(reference: card.reference!),
      ),
    );
  }

  void _openCourse(BuildContext context, DayCard card) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CourseReaderScreen(currentTopic: card),
      ),
    );
  }

  /// Прочитанность — только для сегодняшнего дня: [DayProgress.readTypes]
  /// хранит типы, прочитанные сегодня, и на чужой дате означала бы не то.
  bool _isRead(DayCard card) => _isToday && progress.isRead(card.type);

  /// Обходим кэш репозитория, а после удачного ответа сбрасываем Riverpod,
  /// чтобы экран прочитал уже перезаписанную запись. Старый кэш до успеха не
  /// удаляем: pull-to-refresh в офлайне не должен превращать готовый день в
  /// пустой экран.
  Future<void> _refresh() async {
    final result = await ref.read(getTodayCardsProvider)(
      date,
      forceRefresh: true,
    );
    if (result is Success<TodayCards>) {
      ref.invalidate(dayCardsProvider(dateKey(date)));
    }
  }

  /// Каждый вход открывает первую непрочитанную карточку дня на весь экран:
  /// первый раз это цитата, второй — совет, если до него не дошли, и так далее.
  ///
  /// Весь «момент ага» из §1 требований — открыть приложение и СРАЗУ получить
  /// одну мысль. Список блоков отодвигал его за один тап, и на живом телефоне
  /// это чувствуется потерей. Когда все карточки прочитаны, вкладка открывается
  /// блоками: гнать юзера по кругу незачем.
  ///
  /// Чтение сюда не входит намеренно: уводить в постишное Евангелие без
  /// спроса — это уже не «одна мысль за 15 секунд». К нему ведёт блок-герой.
  void _maybeAutoOpen() {
    if (_autoOpened) return;
    if (!widget.isSelected) return;
    if (!_recordProgress) return;

    final pages = _pages;
    final unread = progress.firstUnreadOf(pages.map((c) => c.type));
    if (unread == null) return;

    final card = pages.firstWhere((c) => c.type == unread);
    _autoOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _open(context, ref, card);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    _maybeAutoOpen();
    final reading = _reading;
    final basics = _basics;
    final courseLink = _courseLink;
    final rest = _pages;

    if (reading == null && basics == null && rest.isEmpty) {
      return Center(
        child: Text(
          'За этот день карточек нет',
          style: TextStyle(fontSize: 14, color: colors.homeSubtitle),
        ),
      );
    }

    final blocks = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Снизу оставляем место под плавающую капсулу навигации: контент
      // уходит под неё, и без запаса последний блок оказался бы закрыт.
      padding: const EdgeInsets.fromLTRB(20, 12, 20, kFloatingNavInset + 32),
      children: [
        if (basics != null) ...[
          BasicsHeroBlock(
            card: basics,
            isRead: _isRead(basics),
            onTap: () => _open(context, ref, basics),
          ),
          const SizedBox(height: 26),
        ],
        if (courseLink != null) ...[
          BasicsCourseLink(
            card: courseLink,
            onTap: () => _openCourse(context, courseLink),
          ),
          const SizedBox(height: 20),
        ],
        if (reading != null) ...[
          ReadingHeroBlock(
            card: reading,
            isRead: _isRead(reading),
            onTap: () => _openReader(context, ref, reading),
          ),
          const SizedBox(height: 26),
        ],
        if (rest.isNotEmpty) ...[
          Text(
            'ЕЩЁ ЗА СЕГОДНЯ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.9,
              color: colors.todayLabel,
            ),
          ),
          const SizedBox(height: 12),
          for (final card in rest) ...[
            DayCardBlock(
              card: card,
              isRead: _isRead(card),
              showReadStatus: !_isFuture,
              onTap: () => _open(context, ref, card),
            ),
            if (card != rest.last) const SizedBox(height: 12),
          ],
        ],
      ],
    );
    return RefreshIndicator(onRefresh: _refresh, child: blocks);
  }
}
