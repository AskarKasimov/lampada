import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../shell/presentation/widgets/floating_nav_bar.dart';
import '../../domain/entities/bible_book.dart';
import 'bible_reader_screen.dart';

/// Книга раскрывает главы; выбранная глава открывается с первого стиха.
class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = (constraints.maxWidth / 62).floor().clamp(
                    4,
                    6,
                  );
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
                      final isSelected = _selectedChapter == chapter;
                      return Material(
                        color: isSelected
                            ? colors.accent
                            : colors.ink.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(11),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(11),
                          onTap: () {
                            setState(() => _selectedChapter = chapter);
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => BibleReaderScreen(
                                  book: book,
                                  chapter: chapter,
                                ),
                              ),
                            );
                          },
                          child: Center(
                            child: Text(
                              '$chapter',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? colors.background
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
      },
    );
  }
}
