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
              icon: const Icon(Icons.info_outline),
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
    if (expanded)
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final book = books[index];
            return _BibleBookTile(
              book: book,
              selected: _selectedBook == book.code,
              statuses: statuses,
              onTap: () => _selectBook(book),
            );
          }, childCount: books.length),
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
        expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
            style: TextStyle(fontSize: 21, color: colors.ink),
          ),
          trailing: Icon(
            selected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: colors.textSecondary,
          ),
          onTap: onTap,
        ),
        if (selected) ...[
          Text(
            'Глава',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = (constraints.maxWidth / 62).floor().clamp(4, 6);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: book.chapterCount,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.3,
                ),
                itemBuilder: (context, chapterIndex) {
                  final chapter = chapterIndex + 1;
                  final id = (book.code, chapter);
                  final isRead = statuses?.read.contains(id) ?? false;
                  final isCached = statuses?.cached.contains(id) ?? false;
                  return Material(
                    key: ValueKey('bible-chapter-${book.code}-$chapter'),
                    color: isRead
                        ? colors.accent
                        : isCached
                        ? colors.background
                        : colors.ink.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                      side: isCached && !isRead
                          ? BorderSide(color: colors.accent, width: 1.5)
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(11),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              BibleReaderScreen(book: book, chapter: chapter),
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
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}
