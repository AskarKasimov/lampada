import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/log/net_log.dart';
import '../../../../core/network/network_status.dart';
import '../../../../core/network/remote_fetch_exception.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/preference_write.dart';
import '../../domain/entities/day_story.dart';
import '../../domain/repositories/day_story_repository.dart';
import '../datasources/day_story_remote_datasource.dart';
import '../dto/day_story_dto.dart';
import '../mappers/day_story_mapper.dart';

/// Кэширует рассказ по самой ссылке, а не по дате: один и тот же праздник
/// повторяется в календаре из года в год, а ссылка — естественный ключ.
///
/// Бюджет свой и отдельный от загрузки дня: экран открывают уже осознанно,
/// со своим ожиданием, и его поход не должен конкурировать за секунды
/// с первой карточкой.
class AzbykaDayStoryRepository implements DayStoryRepository {
  AzbykaDayStoryRepository(
    this._remote,
    this._prefs, {
    Duration budget = const Duration(seconds: 10),
    List<Duration> retryDelays = const [Duration(seconds: 1)],
    NetworkStatus? networkStatus,
  }) : _budget = budget,
       _retryDelays = retryDelays,
       _networkStatus = networkStatus;

  final DayStoryRemoteDatasource _remote;
  final SharedPreferences _prefs;
  final Duration _budget;
  final List<Duration> _retryDelays;
  final NetworkStatus? _networkStatus;

  static const _cachePrefix = 'day_story_cache_v2:';
  static const _cacheIndexKey = 'day_story_cache_index_v2';
  static const _maxCachedStories = 20;
  static const _minAttempt = Duration(milliseconds: 500);

  @override
  Future<Result<DayStory>> fetch(String url) async {
    await _clearLegacyCache();
    final cached = _readCache(url);
    if (cached != null) {
      netLog('рассказ $url из кэша — сеть не трогаем');
      return Success(cached.toEntity());
    }

    if (_networkStatus != null && !await _networkStatus.isOnline()) {
      netLog('сети нет — не запускаем попытки загрузки рассказа $url');
      return Failure(
        AppFailure(
          'Не удалось загрузить рассказ о дне',
          kind: FailureKind.network,
          cause: StateError('Нет активного сетевого подключения'),
        ),
      );
    }

    final elapsed = Stopwatch()..start();
    FailureKind lastKind = FailureKind.unknown;
    Object? lastCause;

    for (var attempt = 0; attempt <= _retryDelays.length; attempt++) {
      final left = _budget - elapsed.elapsed;
      if (left < _minAttempt) break;

      try {
        final dto = await _remote.fetch(url, timeout: left);
        try {
          await _writeCache(url, dto);
        } on Object catch (e) {
          netLog('не удалось записать кэш рассказа $url: $e');
        }
        return Success(dto.toEntity());
      } on RemoteFetchException catch (e) {
        lastKind = e.kind;
        lastCause = e.cause;
        // Вёрстка поменялась — повтор даст ту же ошибку.
        if (e.kind == FailureKind.unknown) break;
      } on Exception catch (e) {
        lastKind = FailureKind.unknown;
        lastCause = e;
        break;
      }

      if (attempt < _retryDelays.length) {
        final left = _budget - elapsed.elapsed;
        if (left <= Duration.zero) break;
        final delay = _retryDelays[attempt];
        await Future<void>.delayed(delay < left ? delay : left);
      }
    }

    netLog('рассказ $url не загрузился: ${lastKind.name}, $lastCause');
    return Failure(
      AppFailure(
        'Не удалось загрузить рассказ о дне',
        kind: lastKind,
        cause: lastCause,
      ),
    );
  }

  Future<void> _writeCache(String url, DayStoryDto dto) async {
    await requirePreferenceWrite(
      _prefs.setString('$_cachePrefix$url', jsonEncode(dto.toJson())),
    );

    final urls = _readCacheIndex()
      ..remove(url)
      ..add(url);
    while (urls.length > _maxCachedStories) {
      final evictedUrl = urls.removeAt(0);
      await requirePreferenceWrite(_prefs.remove('$_cachePrefix$evictedUrl'));
    }
    await requirePreferenceWrite(
      _prefs.setString(_cacheIndexKey, jsonEncode(urls)),
    );
  }

  List<String> _readCacheIndex() {
    final raw = _prefs.getString(_cacheIndexKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<Object?>).whereType<String>().toList();
    } on Object catch (e) {
      netLog('индекс кэша рассказов не разобрался, начинаем заново: $e');
      return [];
    }
  }

  Future<void> _clearLegacyCache() async {
    final legacyKeys = _prefs
        .getKeys()
        .where((key) => key.startsWith('day_story_cache_v1:'))
        .toList();
    for (final key in legacyKeys) {
      try {
        await requirePreferenceWrite(_prefs.remove(key));
      } on Object catch (e) {
        netLog('не удалось удалить старый кэш рассказа $key: $e');
      }
    }
  }

  DayStoryDto? _readCache(String url) {
    final raw = _prefs.getString('$_cachePrefix$url');
    if (raw == null) return null;
    try {
      return DayStoryDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object catch (e) {
      netLog('кэш рассказа $url не разобрался, игнорируем: $e');
      return null;
    }
  }
}
