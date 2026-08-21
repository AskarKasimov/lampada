import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/date_key.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_loading_view.dart';
import '../../../day_story/presentation/screens/day_story_screen.dart';
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
import 'course_reader_screen.dart';

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

  /// Автооткрытие относится ко входу на экран, а не к отдельной странице
  /// [PageView]: листание календаря может пересоздать страницу «Сегодня».
  bool _hasAutoOpened = false;

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
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) => ref
                .read(selectedDateProvider.notifier)
                .select(_pageMapper.dateForPage(page)),
            itemBuilder: (context, page) => _TodayDayPage(
              date: _pageMapper.dateForPage(page),
              hasAutoOpened: _hasAutoOpened,
              onAutoOpened: _markAutoOpened,
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
    final isNeighbour = CalendarPageMapper.dayOffset(selected, date).abs() == 1;
    return isSelected || isNeighbour
        ? _SelectedDayContent(
            date: date,
            isSelected: isSelected,
            hasAutoOpened: hasAutoOpened,
            onAutoOpened: onAutoOpened,
          )
        : const BrandLoadingView();
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
    // Контент важнее ошибки: если карточки на руках есть, показываем их,
    // даже когда последнее обновление упало.
    if (day != null && progress != null) {
      return _DayBlocks(
        date: selected,
        day: _withCourseTopic(selected, day, courseTopic),
        progress: progress,
        isSelected: isSelected,
        courseTopic: courseTopic,
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
    // Седмица стоит НАД полоской, а не над именем святого: это свойство
    // недели, а не дня, и рядом с памятью она читалась как часть её титула.
    //
    // Номер один на всю полоску: у Азбуки седмица идёт с понедельника по
    // субботу, а «Неделя N-я» — это её воскресенье (проверено на августе
    // 2026: сб 8 — Седмица 10-я, вс 9 — Неделя 10-я, пн 10 — Седмица 11-я).
    // Поэтому полоска начинается с понедельника: начни она с воскресенья,
    // в неё попали бы «Неделя 9-я» и «Седмица 10-я» — два разных номера.
    final week = ref.watch(dayCardsProvider(dateKey(selected))).value?.week;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Column(
        children: [
          if ((week ?? '').isNotEmpty) ...[
            Text(
              week!.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.1,
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
          ],
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
    required this.courseTopic,
    required this.hasAutoOpened,
    required this.onAutoOpened,
  });

  final DateTime date;
  final TodayCards day;
  final DayProgress progress;
  final bool isSelected;
  final DayCard? courseTopic;
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
      await _openReader(context, ref, card);
      return;
    }
    if (card.type == CardType.basics) {
      await _openCourse(context, card);
      return;
    }
    final pages = _pages;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CardViewerScreen(
          cards: pages,
          startIndex: pages.indexOf(card),
          date: date,
          recordProgress: _recordProgress,
        ),
      ),
    );
    if (mounted) await _maybeAskReminders();
  }

  /// Просит разрешение на напоминания — один раз, после того как контент
  /// закрыт, а не до него.
  ///
  /// iOS показывает системный запрос ровно один раз за установку. Спросить
  /// на старте значит потратить эту единственную попытку на человека, который
  /// ещё ничего не получил. Здесь он уже прочитал карточку, и вопрос идёт
  /// следом за ценностью, а не перед ней. Прерывать сессию тоже нельзя,
  /// поэтому момент — возврат из просмотрщика, а не переход между карточками.
  Future<void> _maybeAskReminders() async {
    if (!_recordProgress) return;

    // Прогресс читаем из провайдера, а не из widget.progress: отметка
    // «прочитано» ставится асинхронно, и на кадре возврата поле виджета
    // может отставать.
    final read = ref.read(dayProgressProvider).value?.readTypes ?? const {};
    if (read.isEmpty) return;

    // Именно future, а не .value: при первом обращении AsyncNotifier ещё
    // грузится, и проверка по value молча пропускала бы запрос навсегда.
    final settings = await ref.read(reminderSettingsProvider.future);
    if (settings.asked || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const ReminderPermissionScreen(),
      ),
    );
  }

  Future<void> _openReader(
    BuildContext context,
    WidgetRef ref,
    DayCard card,
  ) async {
    ref
        .read(dayProgressProvider.notifier)
        .markRead(card.type, date: date, markVisited: _recordProgress);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReadingScreen(reference: card.reference!),
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

  Future<void> _openCourse(BuildContext context, DayCard card) async {
    // Тему прочитанной отмечает сам CourseReaderScreen, отсюда — НЕ отмечаем.
    // Раньше это делали оба места, и пока курс держал гард «не чаще раза
    // в день», второй вызов был холостым. Гарда больше нет (сколько тем
    // читать за раз, решает юзер), поэтому дубль снова сдвигал бы тему на две
    // за одно открытие — тот самый баг «перескакивает с 1-й на 3-ю».
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CourseReaderScreen(currentTopic: card),
      ),
    );
    if (mounted) await _maybeAskReminders();
  }

  bool _isRead(DayCard card) => _isToday
      ? progress.isRead(card.type)
      : progress.isReadOn(date, card.type);

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

  /// Каждый вход открывает первый невзятый раздел дня: цитата → совет →
  /// притча → Евангелие → основы. Один шаг за вход, порядок задаёт [CardType].
  ///
  /// Весь «момент ага» из §1 требований — открыть приложение и СРАЗУ получить
  /// одну мысль. Список блоков отодвигал его за один тап, и на живом телефоне
  /// это чувствуется потерей. Когда всё прочитано, вкладка открывается
  /// блоками: гнать юзера по кругу незачем.
  ///
  /// Евангелие и курс в очереди стоят наравне с карточками, хотя ведут в свои
  /// ридеры, а не в просмотрщик. Постишное чтение без спроса — это уже не
  /// «одна мысль за 15 секунд», но до него доходит только тот, кто закрыл
  /// первые три, то есть пришёл в приложение не в первый раз за день.
  void _maybeAutoOpen() {
    if (widget.hasAutoOpened) return;
    if (!widget.isSelected) return;
    if (!_recordProgress) return;

    // day.cards уже отсортированы по индексу CardType в GetTodayCards.
    final unread = progress.firstUnreadOf(day.cards.map((c) => c.type));
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

    final brightness = Theme.of(context).brightness;
    final blocks = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Снизу оставляем место под плавающую капсулу навигации: контент
      // уходит под неё, и без запаса последняя запись оказалась бы закрыта.
      padding: const EdgeInsets.fromLTRB(20, 4, 20, kFloatingNavInset + 32),
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
        // Сессия дня: цитата, совет, притча — одна группа, разделённая
        // воздухом. Заголовка у группы нет: «ЕЩЁ ЗА СЕГОДНЯ» называл ядро
        // дня остатком, а сами подписи записей уже говорят, что это.
        for (final card in rest)
          DayEntryRow(
            label: card.type.styleFor(brightness).shortLabel.toUpperCase(),
            text: card.body.replaceAll('\n', ' '),
            isUnread: !_isRead(card),
            showReadStatus: !_isFuture,
            labelColor: card.type.styleFor(brightness).accent,
            onTap: () => _open(context, ref, card),
          ),
        if (reading != null) ...[
          if (rest.isNotEmpty) const DayEntryDivider(),
          DayEntryRow(
            label: 'ЕВАНГЕЛИЕ ДНЯ',
            // В body карточки чтения лежит человекочитаемое «Ин.10:1–9» —
            // это и есть содержание входа, ничего дописывать не нужно.
            text: reading.body,
            isUnread: !_isRead(reading),
            showReadStatus: !_isFuture,
            labelColor: CardType.reading.styleFor(brightness).accent,
            textSize: 27,
            maxLines: 1,
            onTap: () => _openReader(context, ref, reading),
          ),
        ],
        if (basics != null) ...[
          if (rest.isNotEmpty || reading != null) const DayEntryDivider(),
          DayEntryRow(
            label: _courseLabel(basics),
            text: basics.title ?? basicsCourseTitle,
            isUnread: !_isRead(basics),
            showReadStatus: !_isFuture,
            labelColor: CardType.basics.styleFor(brightness).accent,
            textSize: 19,
            onTap: () => _open(context, ref, basics),
          ),
        ],
        if (courseLink != null) ...[
          if (rest.isNotEmpty || reading != null) const DayEntryDivider(),
          DayEntryRow(
            label: _courseLabel(courseLink),
            text: courseLink.title ?? basicsCourseTitle,
            // На чужой дате прочитанность курса не показываем: readTypes
            // хранит прогресс сегодняшнего дня, и метка там значила бы не то.
            isUnread: false,
            labelColor: CardType.basics.styleFor(brightness).accent,
            textSize: 19,
            onTap: () => _openCourse(context, courseLink),
          ),
        ],
      ],
    );
    return RefreshIndicator(onRefresh: _refresh, child: blocks);
  }

  /// «ОСНОВЫ ВЕРЫ · 47». Номер темы берём из id карточки курса — его ставит
  /// [GetCourseTopic], и это единственное место, где он известен.
  String _courseLabel(DayCard card) {
    final number = RegExp(r'^basics-topic-(\d+)$').firstMatch(card.id);
    final title = basicsCourseTitle.toUpperCase();
    return number == null ? title : '$title · ${number.group(1)}';
  }
}
