import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../shell/presentation/widgets/floating_nav_bar.dart';
import '../../domain/entities/bible_book.dart';
import '../providers/providers.dart';
import 'bible_reader_screen.dart';

/// Выбор как на образце: книга раскрывает сетку глав, глава — сетку стихов.
class BibleScreen extends ConsumerStatefulWidget {
  const BibleScreen({super.key});

  @override
  ConsumerState<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends ConsumerState<BibleScreen> {
  static final _books = [...bibleBooks]
    ..sort((a, b) => a.title.compareTo(b.title));

  String? _selectedBook;
  int? _selectedChapter;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, kFloatingNavInset + 20),
      itemCount: _books.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              'Библия',
              style: TextStyle(fontSize: 30, color: colors.ink),
            ),
          );
        }
        final book = _books[index - 1];
        final selected = _selectedBook == book.code;
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
              onTap: () => setState(() {
                _selectedBook = selected ? null : book.code;
                _selectedChapter = null;
              }),
            ),
            if (selected) ...[
              Text(
                'Глава',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(height: 10),
              _NumberGrid(
                count: book.chapterCount,
                selected: _selectedChapter,
                onSelect: (chapter) =>
                    setState(() => _selectedChapter = chapter),
              ),
              if (_selectedChapter case final chapter?) ...[
                const SizedBox(height: 20),
                Text(
                  'Стих',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
                const SizedBox(height: 10),
                _versePicker(book, chapter),
              ],
              const SizedBox(height: 18),
            ],
          ],
        );
      },
    );
  }

  Widget _versePicker(BibleBook book, int chapter) {
    final async = ref.watch(bibleChapterProvider((book.code, chapter)));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Не удалось загрузить стихи'),
          TextButton(
            onPressed: () =>
                ref.invalidate(bibleChapterProvider((book.code, chapter))),
            child: const Text('Повторить'),
          ),
        ],
      ),
      data: (loaded) => _NumberGrid(
        count: loaded.verses.length,
        numbers: [for (final verse in loaded.verses) verse.number],
        onSelect: (verse) => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                BibleReaderScreen(book: book, chapter: chapter, verse: verse),
          ),
        ),
      ),
    );
  }
}

class _NumberGrid extends StatelessWidget {
  const _NumberGrid({
    required this.count,
    required this.onSelect,
    this.selected,
    this.numbers,
  });

  final int count;
  final int? selected;
  final List<int>? numbers;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 62).floor().clamp(4, 6);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.3,
          ),
          itemBuilder: (context, index) {
            final number = numbers?[index] ?? index + 1;
            final isSelected = selected == number;
            return Material(
              color: isSelected
                  ? colors.accent
                  : colors.ink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => onSelect(number),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? colors.background : colors.ink,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
