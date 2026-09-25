import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/bible/domain/bible_chapter_statuses.dart';
import 'package:lampada/features/bible/domain/entities/bible_chapter.dart';
import 'package:lampada/features/bible/domain/repositories/bible_repository.dart';
import 'package:lampada/features/bible/domain/usecases/get_bible_chapter.dart';

class _FakeRepository implements BibleRepository {
  String? requestedBook;
  int? requestedChapter;

  @override
  Future<Result<BibleChapter>> getChapter(String book, int chapter) async {
    requestedBook = book;
    requestedChapter = chapter;
    return const Success(
      BibleChapter(
        book: 'Jn',
        number: 3,
        verses: [BibleVerse(number: 1, text: 'Первый стих')],
      ),
    );
  }

  @override
  Future<Result<BibleChapterStatuses>> getChapterStatuses() async =>
      Success((cached: <BibleChapterId>{}, read: <BibleChapterId>{}));

  @override
  Future<Result<void>> markChapterRead(String book, int chapter) async =>
      const Success(null);
}

void main() {
  test('передаёт выбранную книгу и главу репозиторию', () async {
    final repository = _FakeRepository();
    final result = await GetBibleChapter(repository)('Jn', 3);

    expect(repository.requestedBook, 'Jn');
    expect(repository.requestedChapter, 3);
    expect(
      (result as Success<BibleChapter>).value.verses.single.text,
      'Первый стих',
    );
  });
}
