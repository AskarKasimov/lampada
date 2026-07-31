import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmarks_repository.dart';
import '../dto/bookmark_dto.dart';
import '../mappers/bookmark_mapper.dart';

/// Копилка целиком одним JSON-массивом в prefs: без аккаунта и синхронизации
/// (FR-017), а объёмы тут — десятки записей, не тысячи.
class PrefsBookmarksRepository implements BookmarksRepository {
  PrefsBookmarksRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'bookmarks';

  @override
  Future<Result<List<Bookmark>>> load() async => _guard(_read);

  @override
  Future<Result<List<Bookmark>>> save(Bookmark bookmark) async => _guard(() {
        final current = _read();
        // Пересохранение того же id не двоит запись, а поднимает её наверх.
        final next = [
          bookmark,
          ...current.where((b) => b.id != bookmark.id),
        ];
        _write(next);
        return next;
      });

  @override
  Future<Result<List<Bookmark>>> remove(String id) async => _guard(() {
        final next = _read().where((b) => b.id != id).toList();
        _write(next);
        return next;
      });

  Future<Result<List<Bookmark>>> _guard(List<Bookmark> Function() op) async {
    try {
      return Success(op());
    } on Exception catch (e) {
      return Failure(
        AppFailure(
          'Не удалось открыть копилку',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }

  List<Bookmark> _read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const [];
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => BookmarkDto.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
    // Свежие сверху — порядок задаём при чтении, чтобы он не зависел от того,
    // как запись легла в хранилище.
    list.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return list;
  }

  void _write(List<Bookmark> bookmarks) {
    _prefs.setString(
      _key,
      jsonEncode(bookmarks.map((b) => b.toDto().toJson()).toList()),
    );
  }
}
