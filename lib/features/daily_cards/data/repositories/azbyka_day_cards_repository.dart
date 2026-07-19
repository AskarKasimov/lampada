import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/repositories/day_cards_repository.dart';
import '../datasources/day_cards_remote_datasource.dart';
import '../dto/day_card_dto.dart';
import '../mappers/day_card_mapper.dart';

/// Скрейпит день через [DayCardsRemoteDatasource]. Если в кэше уже лежит
/// набор карточек за запрошенную дату — сеть не дёргаем вовсе. При ошибке
/// сети (или если разметка страницы поменялась) отдаёт последний успешно
/// закэшированный набор карточек, даже если он за другую дату — лучше
/// устаревшие карточки, чем ничего. Единственное место, где исключения
/// data-слоя превращаются в Failure.
class AzbykaDayCardsRepository implements DayCardsRepository {
  AzbykaDayCardsRepository(this._remote, this._prefs);

  final DayCardsRemoteDatasource _remote;
  final SharedPreferences _prefs;

  static const _cacheKey = 'day_cards_cache';

  @override
  Future<Result<List<DayCard>>> getCardsFor(DateTime date) async {
    final cache = _readCache();
    if (cache != null && cache.date == _dateKey(date)) {
      return Success(cache.cards.map((dto) => dto.toEntity()).toList());
    }
    try {
      final dtos = await _remote.fetch(date);
      await _writeCache(date, dtos);
      return Success(dtos.map((dto) => dto.toEntity()).toList());
    } on Exception catch (e) {
      if (cache != null) {
        return Success(cache.cards.map((dto) => dto.toEntity()).toList());
      }
      return Failure(AppFailure('Не удалось загрузить карточки дня', cause: e));
    }
  }

  Future<void> _writeCache(DateTime date, List<DayCardDto> dtos) {
    final json = jsonEncode({
      'date': _dateKey(date),
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

  static String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
