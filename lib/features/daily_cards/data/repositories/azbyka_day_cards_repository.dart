import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/format/date_key.dart';
import '../../../../core/log/net_log.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/entities/today_cards.dart';
import '../../domain/repositories/day_cards_repository.dart';
import '../datasources/day_cards_remote_datasource.dart';
import '../dto/day_card_dto.dart';
import '../mappers/day_card_mapper.dart';

/// Скрейпит день через [DayCardsRemoteDatasource]. Кэш за нужную дату —
/// сеть не трогаем. При сетевой ошибке или сломанной вёрстке отдаём последний
/// закэшированный набор, даже за другую дату — лучше устаревшее, чем ничего.
/// Единственное место, где исключения data-слоя превращаются в Failure.
class AzbykaDayCardsRepository implements DayCardsRepository {
  AzbykaDayCardsRepository(
    this._remote,
    this._prefs, {
    Duration budget = const Duration(seconds: 10),
    Duration attemptTimeout = const Duration(seconds: 3),
    List<Duration> retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 1),
    ],
  })  : _budget = budget,
        _attemptTimeout = attemptTimeout,
        _retryDelays = retryDelays;

  final DayCardsRemoteDatasource _remote;
  final SharedPreferences _prefs;

  /// Потолок на весь цикл попыток — время, которое видит юзер в мёртвой сети
  /// (captive portal). 10 секунд, потому что сплэш показывает спиннер через
  /// 3с: с индикатором ожидание читается как работа, без него — как зависание.
  final Duration _budget;
  final Duration _attemptTimeout;
  final List<Duration> _retryDelays;

  static const _cacheKey = 'day_cards_cache';

  /// Меньше этого остатка попытку не начинаем — она гарантированно не успеет.
  static const _minAttempt = Duration(milliseconds: 500);

  @override
  Future<Result<TodayCards>> getCardsFor(DateTime date) async {
    final cache = _readCache();
    netLog(
      'запрошено ${dateKey(date)}, в кэше '
      '${cache == null ? 'пусто' : cache.date}, '
      'бюджет ${_budget.inMilliseconds}мс, '
      'попыток максимум ${_retryDelays.length + 1}',
    );
    if (cache != null && cache.date == dateKey(date)) {
      netLog('кэш за нужную дату — сеть не трогаем');
      return Success(TodayCards(cards: _toEntities(cache.cards)));
    }

    final elapsed = Stopwatch()..start();
    FailureKind lastKind = FailureKind.unknown;
    Object? lastCause;

    for (var attempt = 0; attempt <= _retryDelays.length; attempt++) {
      final left = _budget - elapsed.elapsed;
      if (left < _minAttempt) {
        netLog('бюджет исчерпан (осталось ${left.inMilliseconds}мс) — стоп');
        break;
      }

      try {
        netLog('попытка ${attempt + 1}, остаток бюджета '
            '${left.inMilliseconds}мс');
        final dtos = await _remote.fetch(
          date,
          timeout: left < _attemptTimeout ? left : _attemptTimeout,
        );
        await _writeCache(date, dtos);
        netLog('успех на попытке ${attempt + 1} за '
            '${elapsed.elapsedMilliseconds}мс — отдаём свежие');
        return Success(TodayCards(cards: _toEntities(dtos)));
      } on RemoteFetchException catch (e) {
        lastKind = e.kind;
        lastCause = e.cause;
        netLog('попытка ${attempt + 1} провалилась: ${e.kind.name}');
        // Вёрстка поменялась — повтор даст ту же ошибку, только сожжёт бюджет.
        if (e.kind == FailureKind.unknown) {
          netLog('вид unknown — не ретраим');
          break;
        }
      } on Exception catch (e) {
        lastKind = FailureKind.unknown;
        lastCause = e;
        netLog('неожиданное исключение, не ретраим: $e');
        break;
      }

      if (attempt < _retryDelays.length) {
        await Future<void>.delayed(_retryDelays[attempt]);
      }
    }

    if (cache != null) {
      netLog('всё упало за ${elapsed.elapsedMilliseconds}мс — '
          'отдаём кэш за ${cache.date} как stale');
      return Success(
        TodayCards(
          cards: _toEntities(cache.cards),
          staleDate: DateTime.parse(cache.date),
        ),
      );
    }
    netLog('всё упало за ${elapsed.elapsedMilliseconds}мс, кэша нет — '
        'офлайн-экран, kind=${lastKind.name}, причина: $lastCause');
    return Failure(
      AppFailure(
        'Не удалось загрузить карточки дня',
        kind: lastKind,
        cause: lastCause,
      ),
    );
  }

  static List<DayCard> _toEntities(List<DayCardDto> dtos) =>
      dtos.map((dto) => dto.toEntity()).toList();

  Future<void> _writeCache(DateTime date, List<DayCardDto> dtos) {
    final json = jsonEncode({
      'date': dateKey(date),
      'cards': dtos.map((d) => d.toJson()).toList(),
    });
    return _prefs.setString(_cacheKey, json);
  }

  ({String date, List<DayCardDto> cards})? _readCache() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final cards = (map['cards'] as List<dynamic>)
        .map((c) => DayCardDto.fromJson(c as Map<String, dynamic>))
        .toList();
    return (date: map['date'] as String, cards: cards);
  }
}
