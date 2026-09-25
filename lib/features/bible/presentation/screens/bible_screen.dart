import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../shell/presentation/widgets/floating_nav_bar.dart';
import '../../domain/entities/bible_book.dart';
import 'bible_reader_screen.dart';

/// Книга сразу открывает чтение с первого стиха первой главы.
class BibleScreen extends StatelessWidget {
  const BibleScreen({super.key});

  static final _books = [...bibleBooks]
    ..sort((a, b) => a.title.compareTo(b.title));

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
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            book.title,
            style: TextStyle(fontSize: 21, color: colors.ink),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BibleReaderScreen(book: book),
            ),
          ),
        );
      },
    );
  }
}
