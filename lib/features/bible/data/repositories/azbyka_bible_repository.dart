import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/log/net_log.dart';
import '../../../../core/network/remote_fetch_exception.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/preference_write.dart';
import '../../domain/bible_chapter_statuses.dart';
import '../../domain/entities/bible_book.dart';
import '../../domain/entities/bible_chapter.dart';
import '../../domain/repositories/bible_repository.dart';
import '../datasources/bible_remote_datasource.dart';
import '../dto/bible_chapter_dto.dart';
import '../mappers/bible_chapter_mapper.dart';

class AzbykaBibleRepository implements BibleRepository {
  AzbykaBibleRepository(this._source, this._prefs);

  final BibleRemoteDatasource _source;
  final SharedPreferences _prefs;
  static const _cachePrefix = 'bible_chapter_v1:';
  static const _progressPrefix = 'bible_progress_v1:';
  static const _lastChapterKey = 'bible_last_chapter_v1';
  static const _readKey = 'bible_read_chapters_v1';
  Future<void> _pendingProgressWrite = Future.value();
  Future<void> _pendingReadWrite = Future.value();

  @override
  Future<Result<BibleChapter>> getChapter(String book, int chapter) async {
    try {
      final cached = _readCache(book, chapter);
      if (cached != null) return Success(cached.toEntity());
      final downloaded = await _source.fetchChapter(book, chapter);
      try {
        await requirePreferenceWrite(
          _prefs.setString(
            '$_cachePrefix$book.$chapter',
            jsonEncode(downloaded.toJson()),
          ),
        );
      } on Object catch (error) {
        // Текст остаётся доступен сейчас, но без записи не получит статус офлайн.
        netLog('не удалось сохранить главу $book.$chapter: $error');
      }
      return Success(downloaded.toEntity());
    } on RemoteFetchException catch (error) {
      return Failure(
        AppFailure(
          'Не удалось загрузить главу',
          kind: error.kind,
          cause: error,
        ),
      );
    } on Object catch (error) {
      return Failure(
        AppFailure(
          'Не удалось прочитать главу',
          kind: FailureKind.unknown,
          cause: error,
        ),
      );
    }
  }

  @override
  Future<Result<BibleChapterStatuses>> getChapterStatuses() async {
    try {
      // Повторный вход может опередить запись последнего свайпа.
      await _pendingProgressWrite;
      await _pendingReadWrite;
      final cached = <BibleChapterId>{};
      for (final key in _prefs.getKeys()) {
        if (!key.startsWith(_cachePrefix)) continue;
        final parts = key.substring(_cachePrefix.length).split('.');
        if (parts.length != 2) continue;
        final chapter = int.tryParse(parts[1]);
        if (chapter == null || _readCache(parts[0], chapter) == null) continue;
        cached.add((parts[0], chapter));
      }
      final progress = <BibleChapterId, BibleChapterProgress>{};
      for (final key in _prefs.getKeys()) {
        if (!key.startsWith(_progressPrefix)) continue;
        final parts = key.substring(_progressPrefix.length).split('.');
        if (parts.length != 2) continue;
        final chapter = int.tryParse(parts[1]);
        if (chapter == null || chapter < 1) continue;
        try {
          final json =
              jsonDecode(_prefs.getString(key)!) as Map<String, dynamic>;
          final verse = json['verse'] as int;
          final fraction = (json['fraction'] as num).toDouble();
          if (verse < 1 ||
              !fraction.isFinite ||
              fraction <= 0 ||
              fraction > 1) {
            continue;
          }
          progress[(parts[0], chapter)] = (verse: verse, fraction: fraction);
        } on Object catch (error) {
          // Повреждённая позиция одной главы не скрывает остальные статусы.
          netLog('прогресс главы ${parts.join(".")} повреждён: $error');
        }
      }
      return Success((
        lastChapter: _lastChapter(progress),
        cached: cached,
        read: _readChapters(),
        progress: progress,
      ));
    } on Object catch (error) {
      return Failure(
        AppFailure(
          'Не удалось открыть прогресс Библии',
          kind: FailureKind.unknown,
          cause: error,
        ),
      );
    }
  }

  @override
  Future<Result<void>> markChapterRead(String book, int chapter) {
    final operation = _pendingReadWrite.then((_) async {
      try {
        final read = _readChapters()..add((book, chapter));
        await requirePreferenceWrite(
          _prefs.setStringList(_readKey, [
            for (final id in read) '${id.$1}.${id.$2}',
          ]),
        );
        return const Success<void>(null);
      } on Object catch (error) {
        return Failure<void>(
          AppFailure(
            'Не удалось сохранить прочитанную главу',
            kind: FailureKind.unknown,
            cause: error,
          ),
        );
      }
    });
    _pendingReadWrite = operation.then((_) {});
    return operation;
  }

  @override
  Future<Result<void>> saveChapterProgress(
    String book,
    int chapter,
    BibleChapterProgress progress,
  ) {
    // Последовательные записи сохраняют последний свайп даже при быстром листании.
    final operation = _pendingProgressWrite.then((_) async {
      try {
        await requirePreferenceWrite(
          _prefs.setString(
            '$_progressPrefix$book.$chapter',
            jsonEncode({
              'verse': progress.verse,
              'fraction': progress.fraction,
            }),
          ),
        );
        await requirePreferenceWrite(
          _prefs.setString(_lastChapterKey, '$book.$chapter'),
        );
        return const Success<void>(null);
      } on Object catch (error) {
        return Failure<void>(
          AppFailure(
            'Не удалось сохранить место чтения',
            kind: FailureKind.unknown,
            cause: error,
          ),
        );
      }
    });
    _pendingProgressWrite = operation.then((_) {});
    return operation;
  }

  BibleChapterId? _lastChapter(
    Map<BibleChapterId, BibleChapterProgress> progress,
  ) {
    final parts = _prefs.getString(_lastChapterKey)?.split('.');
    if (parts == null || parts.length != 2) return null;
    final chapter = int.tryParse(parts[1]);
    if (chapter == null || !progress.containsKey((parts[0], chapter))) {
      return null;
    }
    if (!bibleBooks.any(
      (book) =>
          book.code == parts[0] && chapter >= 1 && chapter <= book.chapterCount,
    )) {
      return null;
    }
    return (parts[0], chapter);
  }

  BibleChapterDto? _readCache(String book, int chapter) {
    final raw = _prefs.getString('$_cachePrefix$book.$chapter');
    if (raw == null) return null;
    try {
      final dto = BibleChapterDto.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (dto.book != book || dto.number != chapter || dto.verses.isEmpty) {
        return null;
      }
      return dto;
    } on Object catch (error) {
      netLog('кэш главы $book.$chapter повреждён: $error');
      return null;
    }
  }

  Set<BibleChapterId> _readChapters() {
    final read = <BibleChapterId>{};
    for (final raw in _prefs.getStringList(_readKey) ?? const <String>[]) {
      final parts = raw.split('.');
      if (parts.length != 2) continue;
      final chapter = int.tryParse(parts[1]);
      if (chapter != null) read.add((parts[0], chapter));
    }
    return read;
  }
}
