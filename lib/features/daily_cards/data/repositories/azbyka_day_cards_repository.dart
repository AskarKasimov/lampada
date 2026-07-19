import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/repositories/day_cards_repository.dart';
import '../datasources/day_cards_remote_datasource.dart';
import '../dto/day_card_dto.dart';
import '../mappers/day_card_mapper.dart';

/// Скрейпит день через [DayCardsRemoteDatasource]; при ошибке (сеть или
/// разметка страницы поменялась) отдаёт последний успешно закэшированный
/// набор карточек, если он есть. Единственное место, где исключения
/// data-слоя превращаются в Failure.
class AzbykaDayCardsRepository implements DayCardsRepository {
  AzbykaDayCardsRepository(this._remote, this._prefs);

  final DayCardsRemoteDatasource _remote;
  final SharedPreferences _prefs;

  static const _cacheKey = 'day_cards_cache';

  @override
  Future<Result<List<DayCard>>> getCardsFor(DateTime date) async {
    try {
      final dtos = await _remote.fetch(date);
      await _writeCache(date, dtos);
      return Success(dtos.map((dto) => dto.toEntity()).toList());
    } on Exception catch (e) {
      final cached = _readCache();
      if (cached != null) {
        return Success(cached.map((dto) => dto.toEntity()).toList());
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

  List<DayCardDto>? _readCache() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final cards = map['cards'] as List<dynamic>;
    return cards
        .map((c) => DayCardDto.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  static String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
