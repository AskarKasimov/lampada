import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../shell/presentation/widgets/floating_nav_bar.dart';
import '../../domain/bible_chapter_statuses.dart';
import '../../domain/entities/bible_book.dart';
import '../providers/providers.dart';
import 'bible_info_screen.dart';
import 'bible_reader_screen.dart';

/// Книга раскрывает главы; выбранная глава открывается с сохранённого стиха.
class BibleScreen extends ConsumerStatefulWidget {
  const BibleScreen({this.selectChapter = false, super.key});

  final bool selectChapter;

  @override
  ConsumerState<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends ConsumerState<BibleScreen> {
  // Каталог хранит книги в каноническом порядке: Новый Завет начинается с Mt.
  static final _oldTestamentBooks = [
    ...bibleBooks.takeWhile((book) => book.code != 'Mt'),
  ]..sort((a, b) => a.title.compareTo(b.title));
  static final _newTestamentBooks =
      [...bibleBooks.skipWhile((book) => book.code != 'Mt')]..sort((a, b) {
        const gospels = ['Mt', 'Mk', 'Lk', 'Jn'];
        final ai = gospels.indexOf(a.code);
        final bi = gospels.indexOf(b.code);
        if (ai >= 0 || bi >= 0) {
          return (ai < 0 ? 4 : ai).compareTo(bi < 0 ? 4 : bi);
        }
        return a.title.compareTo(b.title);
      });
  String? _selectedBook;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final navInset = FloatingNavInset.of(context);
    final statuses = ref.watch(bibleChapterStatusesProvider).value;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
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
          statuses: statuses,
          colors: colors,
        ),
        ..._testamentSlivers(
          title: 'Ветхий Завет',
          books: _oldTestamentBooks,
          statuses: statuses,
          colors: colors,
        ),
        SliverToBoxAdapter(child: SizedBox(height: navInset)),
      ],
    );
  }

  List<Widget> _testamentSlivers({
    required String title,
    required List<BibleBook> books,
    required BibleChapterStatuses? statuses,
    required AppColorsExtension colors,
  }) => [
    SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _TestamentHeaderDelegate(title: title, colors: colors),
        ),
        SliverList.builder(
          itemCount: books.length,
          itemBuilder: (context, index) => _BibleBookTile(
            book: books[index],
            selected: _selectedBook == books[index].code,
            statuses: statuses,
            selectChapter: widget.selectChapter,
            onTap: () => _selectBook(books[index]),
          ),
        ),
      ],
    ),
  ];

  void _selectBook(BibleBook book) => setState(() {
    _selectedBook = _selectedBook == book.code ? null : book.code;
  });
}

/// Группа ограничивает закрепление своим заветом: следующий заголовок
/// вытесняет предыдущий, не создавая второй закреплённой строки.
class _TestamentHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TestamentHeaderDelegate({required this.title, required this.colors});

  final String title;
  final AppColorsExtension colors;

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Material(
    color: colors.background,
    child: Padding(
      padding: AppSpacing.of(context).horizontal,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.ink,
          ),
        ),
      ),
    ),
  );

  @override
  bool shouldRebuild(_TestamentHeaderDelegate oldDelegate) =>
      title != oldDelegate.title || colors != oldDelegate.colors;
}

const _accordionDuration = Duration(milliseconds: 400);

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

class _BibleBookTile extends StatelessWidget {
  const _BibleBookTile({
    required this.book,
    required this.selected,
    required this.statuses,
    required this.onTap,
    required this.selectChapter,
  });

  final BibleBook book;
  final bool selected;
  final BibleChapterStatuses? statuses;
  final VoidCallback onTap;
  final bool selectChapter;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: AppSpacing.of(context).horizontal,
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
              ? Padding(
                  padding: AppSpacing.of(context).horizontal,
                  child: Column(
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
                              final isRead =
                                  statuses?.read.contains(id) ?? false;
                              final isCached =
                                  statuses?.cached.contains(id) ?? false;
                              final progress = statuses?.progress[id];
                              return Material(
                                key: ValueKey(
                                  'bible-chapter-${book.code}-$chapter',
                                ),
                                clipBehavior: Clip.antiAlias,
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
                                  onTap: () {
                                    if (selectChapter) {
                                      Navigator.of(context).pop((
                                        book,
                                        chapter,
                                        progress?.verse ?? 1,
                                      ));
                                      return;
                                    }
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        fullscreenDialog: true,
                                        builder: (_) => BibleReaderScreen(
                                          book: book,
                                          chapter: chapter,
                                          initialVerse: progress?.verse ?? 1,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      if (!isRead && progress != null)
                                        Positioned.fill(
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: FractionallySizedBox(
                                              widthFactor: progress.fraction,
                                              heightFactor: 1,
                                              child: Ink(
                                                key: ValueKey(
                                                  'bible-progress-${book.code}-$chapter',
                                                ),
                                                color: colors.accent.withValues(
                                                  alpha: 0.22,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      Center(
                                        child: Text(
                                          '$chapter',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: isRead
                                                ? colors.background
                                                : progress != null
                                                ? colors.ink
                                                : isCached
                                                ? colors.accent
                                                : colors.ink,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
