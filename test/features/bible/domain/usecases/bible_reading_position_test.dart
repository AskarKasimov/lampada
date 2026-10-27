import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/bible/domain/bible_chapter_statuses.dart';
import 'package:lampada/features/bible/domain/entities/bible_chapter.dart';
import 'package:lampada/features/bible/domain/entities/bible_reading_position.dart';
import 'package:lampada/features/bible/domain/repositories/bible_repository.dart';
import 'package:lampada/features/bible/domain/usecases/load_bible_reading_position.dart';
import 'package:lampada/features/bible/domain/usecases/save_bible_reading_position.dart';

class _Repository implements BibleRepository {
  BibleReadingPosition? position;

  @override
  Future<Result<BibleReadingPosition?>> getReadingPosition() async =>
      Success(position);

  @override
  Future<Result<void>> saveReadingPosition(
    BibleReadingPosition position,
  ) async {
    this.position = position;
    return const Success(null);
  }

  @override
  Future<Result<BibleChapter>> getChapter(String book, int chapter) =>
      throw UnimplementedError();

  @override
  Future<Result<BibleChapterStatuses>> getChapterStatuses() =>
      throw UnimplementedError();

  @override
  Future<Result<void>> markChapterRead(String book, int chapter) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> saveChapterProgress(
    String book,
    int chapter,
    BibleChapterProgress progress,
  ) => throw UnimplementedError();
}

void main() {
  test(
    'load use case returns the independent position from the repository',
    () async {
      final repository = _Repository()
        ..position = const BibleReadingPosition(
          book: 'Rom',
          chapter: 8,
          verse: 12,
        );

      final result = await LoadBibleReadingPosition(repository)();

      expect(
        (result as Success<BibleReadingPosition?>).value,
        repository.position,
      );
    },
  );

  test('save use case writes the complete position', () async {
    final repository = _Repository();
    const position = BibleReadingPosition(book: 'Jn', chapter: 3, verse: 16);

    expect(
      await SaveBibleReadingPosition(repository)(position),
      isA<Success<void>>(),
    );
    expect(repository.position, position);
  });
}
