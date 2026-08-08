import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/log/net_log.dart';
import '../../../../core/network/network_status.dart';
import '../../../../core/network/remote_fetch_exception.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/preference_write.dart';
import '../../domain/entities/daily_reading.dart';
import '../../domain/repositories/reading_repository.dart';
import '../datasources/reading_remote_datasource.dart';
import '../dto/daily_reading_dto.dart';
import '../mappers/daily_reading_mapper.dart';

/// Кэширует отрывок по самой ссылке, а не по дате: один и тот же отрывок
/// попадается в календаре не раз, а ссылка — естественный ключ.
///
/// Бюджет свой и отдельный от загрузки дня: ридер открывают уже осознанно,
/// с экраном ожидания, и его два-три похода не должны конкурировать за
/// секунды с первой карточкой.
class AzbykaReadingRepository implements ReadingRepository {
  AzbykaReadingRepository(
    this._remote,
    this._prefs, {
    Duration budget = const Duration(seconds: 12),
    List<Duration> retryDelays = const [Duration(seconds: 1)],
    NetworkStatus? networkStatus,
  }) : _budget = budget,
       _retryDelays = retryDelays,
       _networkStatus = networkStatus;

  final ReadingRemoteDatasource _remote;
  final SharedPreferences _prefs;
  final Duration _budget;
  final List<Duration> _retryDelays;
  final NetworkStatus? _networkStatus;

  /// Версия в ключе, а не в теле записи: поля толкования у стиха
  /// необязательные, поэтому запись предыдущей схемы разбиралась БЕЗ ошибки
  /// и отдавала чтение вовсе без толкований — в интерфейсе не оставалось
  /// ничего, что можно тапнуть. Схема стихов меняется — версия растёт.
  static const _cachePrefix = 'reading_cache_v2:';
  static const _minAttempt = Duration(milliseconds: 500);

  @override
  Future<Result<DailyReading>> getReading(String reference) async {
    final cached = _readCache(reference);
    if (cached != null) {
      netLog('чтение $reference из кэша — сеть не трогаем');
      return Success(cached.toEntity());
    }

    if (_networkStatus != null && !await _networkStatus.isOnline()) {
      netLog('сети нет — не запускаем попытки загрузки чтения $reference');
      return Failure(
        AppFailure(
          'Не удалось загрузить чтение дня',
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
        final dto = await _remote.fetch(reference, timeout: left);
        try {
          await _writeCache(reference, dto);
        } on Exception catch (e) {
          netLog('не удалось записать кэш чтения $reference: $e');
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
        await Future<void>.delayed(_retryDelays[attempt]);
      }
    }

    netLog('чтение $reference не загрузилось: ${lastKind.name}, $lastCause');
    return Failure(
      AppFailure(
        'Не удалось загрузить чтение дня',
        kind: lastKind,
        cause: lastCause,
      ),
    );
  }

  Future<void> _writeCache(String reference, DailyReadingDto dto) =>
      requirePreferenceWrite(
        _prefs.setString('$_cachePrefix$reference', jsonEncode(dto.toJson())),
      );

  DailyReadingDto? _readCache(String reference) {
    final raw = _prefs.getString('$_cachePrefix$reference');
    if (raw == null) return null;
    try {
      return DailyReadingDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      // Кэш от прошлой версии схемы — не повод падать, просто сходим в сеть.
      netLog('кэш чтения $reference не разобрался, игнорируем: $e');
      return null;
    }
  }
}
