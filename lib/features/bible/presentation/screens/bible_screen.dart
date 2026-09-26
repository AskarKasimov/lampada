import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../shell/presentation/widgets/floating_nav_bar.dart';
import '../../domain/bible_chapter_statuses.dart';
import '../../domain/entities/bible_book.dart';
import '../providers/providers.dart';
import 'bible_info_screen.dart';
import 'bible_reader_screen.dart';

/// Книга раскрывает главы; выбранная глава открывается с первого стиха.
class BibleScreen extends ConsumerStatefulWidget {
  const BibleScreen({super.key});

  @override
  ConsumerState<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends ConsumerState<BibleScreen> {
  // Каталог хранит книги в каноническом порядке: Новый Завет начинается с Mt.
  static final _oldTestamentBooks = [
    ...bibleBooks.takeWhile((book) => book.code != 'Mt'),
  ]..sort((a, b) => a.title.compareTo(b.title));
  static final _newTestamentBooks = [
    ...bibleBooks.skipWhile((book) => book.code != 'Mt'),
  ]..sort((a, b) => a.title.compareTo(b.title));
  String? _selectedBook;
  final _expandedTestaments = <String>{};

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final statuses = ref.watch(bibleChapterStatusesProvider).value;
    final newTestamentExpanded = _expandedTestaments.contains('Новый Завет');
    final oldTestamentExpanded = _expandedTestaments.contains('Ветхий Завет');
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          titleSpacing: 20,
          backgroundColor: colors.background,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text('Библия', style: TextStyle(color: colors.ink)),
          actions: [
            IconButton(
              tooltip: 'Помощь',
              color: colors.textSecondary,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BibleInfoScreen(),
                ),
              ),
              icon: const Icon(CupertinoIcons.info),
            ),
          ],
        ),
        ..._testamentSlivers(
          title: 'Новый Завет',
          books: _newTestamentBooks,
          expanded: newTestamentExpanded,
          statuses: statuses,
          colors: colors,
        ),
        ..._testamentSlivers(
          title: 'Ветхий Завет',
          books: _oldTestamentBooks,
          expanded: oldTestamentExpanded,
          statuses: statuses,
          colors: colors,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: kFloatingNavInset)),
      ],
    );
  }

  List<Widget> _testamentSlivers({
    required String title,
    required List<BibleBook> books,
    required bool expanded,
    required BibleChapterStatuses? statuses,
    required AppColorsExtension colors,
  }) => [
    if (expanded)
      SliverPersistentHeader(
        pinned: true,
        delegate: _TestamentHeaderDelegate(
          title: title,
          expanded: expanded,
          colors: colors,
          onToggle: () => _toggleTestament(title),
        ),
      )
    else
      SliverToBoxAdapter(
        child: _TestamentHeader(
          title: title,
          expanded: false,
          colors: colors,
          onToggle: () => _toggleTestament(title),
        ),
      ),
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: _TestamentBooks(
        books: books,
        expanded: expanded,
        selectedBook: _selectedBook,
        statuses: statuses,
        onSelect: _selectBook,
      ),
    ),
  ];

  void _toggleTestament(String testament) => setState(() {
    if (!_expandedTestaments.add(testament)) {
      _expandedTestaments.remove(testament);
    }
  });

  void _selectBook(BibleBook book) => setState(() {
    _selectedBook = _selectedBook == book.code ? null : book.code;
  });
}

const _accordionDuration = Duration(milliseconds: 400);

Duration _motionDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : _accordionDuration;

class _AccordionSize extends StatelessWidget {
  const _AccordionSize({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Нулевая длительность AnimatedSize перезапускает layout синхронно.
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedSize(
      duration: _accordionDuration,
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}

/// SliverAnimatedList сохраняет ленивую отрисовку длинного каталога и
/// удерживает удаляемые строки до завершения сворачивания.
class _TestamentBooks extends StatefulWidget {
  const _TestamentBooks({
    required this.books,
    required this.expanded,
    required this.selectedBook,
    required this.statuses,
    required this.onSelect,
  });

  final List<BibleBook> books;
  final bool expanded;
  final String? selectedBook;
  final BibleChapterStatuses? statuses;
  final ValueChanged<BibleBook> onSelect;

  @override
  State<_TestamentBooks> createState() => _TestamentBooksState();
}

class _TestamentBooksState extends State<_TestamentBooks> {
  final _listKey = GlobalKey<SliverAnimatedListState>();

  @override
  void didUpdateWidget(_TestamentBooks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded == oldWidget.expanded) return;
    final duration = _motionDuration(context);
    if (widget.expanded) {
      _listKey.currentState!.insertAllItems(
        0,
        widget.books.length,
        duration: duration,
      );
    } else {
      for (var index = widget.books.length - 1; index >= 0; index--) {
        final book = widget.books[index];
        _listKey.currentState!.removeItem(
          index,
          (context, animation) => _tile(book, animation),
          duration: duration,
        );
      }
    }
  }

  Widget _tile(BibleBook book, Animation<double> animation) => SizeTransition(
    sizeFactor: animation.drive(CurveTween(curve: Curves.easeInOutCubic)),
    child: _BibleBookTile(
      book: book,
      selected: widget.selectedBook == book.code,
      statuses: widget.statuses,
      onTap: () => widget.onSelect(book),
    ),
  );

  @override
  Widget build(BuildContext context) => SliverAnimatedList(
    key: _listKey,
    initialItemCount: widget.expanded ? widget.books.length : 0,
    itemBuilder: (context, index, animation) =>
        _tile(widget.books[index], animation),
  );
}

class _TestamentTile extends StatelessWidget {
  const _TestamentTile({
    required this.title,
    required this.expanded,
    required this.onToggle,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colors.ink,
        ),
      ),
      trailing: Icon(
        expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
        color: colors.textSecondary,
      ),
      onTap: onToggle,
    );
  }
}

class _TestamentHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TestamentHeaderDelegate({
    required this.title,
    required this.expanded,
    required this.colors,
    required this.onToggle,
  });

  final String title;
  final bool expanded;
  final AppColorsExtension colors;
  final VoidCallback onToggle;

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => _TestamentHeader(
    title: title,
    expanded: expanded,
    colors: colors,
    onToggle: onToggle,
  );

  @override
  bool shouldRebuild(_TestamentHeaderDelegate oldDelegate) =>
      title != oldDelegate.title ||
      expanded != oldDelegate.expanded ||
      colors != oldDelegate.colors;
}

class _TestamentHeader extends StatelessWidget {
  const _TestamentHeader({
    required this.title,
    required this.expanded,
    required this.colors,
    required this.onToggle,
  });

  final String title;
  final bool expanded;
  final AppColorsExtension colors;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Material(
    color: colors.background,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _TestamentTile(
        title: title,
        expanded: expanded,
        onToggle: onToggle,
      ),
    ),
  );
}

class _BibleBookTile extends StatelessWidget {
  const _BibleBookTile({
    required this.book,
    required this.selected,
    required this.statuses,
    required this.onTap,
  });

  final BibleBook book;
  final bool selected;
  final BibleChapterStatuses? statuses;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            book.title,
            style: TextStyle(fontSize: 17, color: colors.ink),
          ),
          trailing: Icon(
            selected ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
            color: colors.textSecondary,
          ),
          onTap: onTap,
        ),
        _AccordionSize(
          child: selected
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      'Глава',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = (constraints.maxWidth / 62)
                            .floor()
                            .clamp(4, 6);
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: book.chapterCount,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                                childAspectRatio: 1.3,
                              ),
                          itemBuilder: (context, chapterIndex) {
                            final chapter = chapterIndex + 1;
                            final id = (book.code, chapter);
                            final isRead = statuses?.read.contains(id) ?? false;
                            final isCached =
                                statuses?.cached.contains(id) ?? false;
                            return Material(
                              key: ValueKey(
                                'bible-chapter-${book.code}-$chapter',
                              ),
                              color: isRead
                                  ? colors.accent
                                  : isCached
                                  ? colors.background
                                  : colors.ink.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                                side: isCached && !isRead
                                    ? BorderSide(
                                        color: colors.accent,
                                        width: 1.5,
                                      )
                                    : BorderSide.none,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(11),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    fullscreenDialog: true,
                                    builder: (_) => BibleReaderScreen(
                                      book: book,
                                      chapter: chapter,
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '$chapter',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: isRead
                                          ? colors.background
                                          : isCached
                                          ? colors.accent
                                          : colors.ink,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
