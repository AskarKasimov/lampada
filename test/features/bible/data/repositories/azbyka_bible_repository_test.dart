import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/bible/data/datasources/bible_remote_datasource.dart';
import 'package:lampada/features/bible/data/dto/bible_chapter_dto.dart';
import 'package:lampada/features/bible/data/repositories/azbyka_bible_repository.dart';
import 'package:lampada/features/bible/domain/bible_chapter_statuses.dart';
import 'package:lampada/features/bible/domain/entities/bible_chapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Source implements BibleRemoteDatasource {
  int calls = 0;

  @override
  Future<BibleChapterDto> fetchChapter(String book, int chapter) async {
    calls++;
    if (calls > 1) throw Exception('нет сети');
    return BibleChapterDto(
      book: book,
      number: chapter,
      verses: const [BibleVerseDto(number: 1, text: 'Стих')],
    );
  }
}

void main() {
  test('быстрые отметки разных глав сохраняются обе', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = AzbykaBibleRepository(_Source(), prefs);

    await Future.wait([
      repository.markChapterRead('Jn', 3),
      repository.markChapterRead('Jn', 4),
    ]);
    final status =
        (await repository.getChapterStatuses() as Success<BibleChapterStatuses>)
            .value;
    expect(status.read, containsAll([('Jn', 3), ('Jn', 4)]));
  });

  test(
    'скачанная глава доступна офлайн и сохраняет статус прочтения',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final source = _Source();
      final first = AzbykaBibleRepository(source, prefs);

      expect(await first.getChapter('Jn', 3), isA<Success<BibleChapter>>());
      final downloaded =
          (await first.getChapterStatuses() as Success<BibleChapterStatuses>)
              .value;
      expect(downloaded.cached, contains(('Jn', 3)));
      expect(downloaded.read, isEmpty);

      expect(await first.markChapterRead('Jn', 3), isA<Success<void>>());
      final reopened = AzbykaBibleRepository(source, prefs);
      final offline = await reopened.getChapter('Jn', 3);
      expect(
        (offline as Success<BibleChapter>).value.verses.single.text,
        'Стих',
      );
      expect(source.calls, 1);
      final status =
          (await reopened.getChapterStatuses() as Success<BibleChapterStatuses>)
              .value;
      expect(status.cached, contains(('Jn', 3)));
      expect(status.read, contains(('Jn', 3)));
    },
  );
}
