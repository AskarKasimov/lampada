import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/format/date_key.dart';
import '../../../../core/log/net_log.dart';
import '../../../../core/network/network_status.dart';
import '../../../../core/network/remote_fetch_exception.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/preference_write.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/entities/today_cards.dart';
import '../../domain/repositories/day_cards_repository.dart';
import '../datasources/day_cards_remote_datasource.dart';
import '../dto/day_dto.dart';
import '../mappers/day_card_mapper.dart';

/// Скрейпит день через [DayCardsRemoteDatasource]. Кэш за нужную дату —
/// сеть не трогаем. При сетевой ошибке или сломанной вёрстке без кэша нужной
/// даты честно отдаём Failure: чужой день нельзя выдавать за выбранный.
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
    NetworkStatus? networkStatus,
  }) : _budget = budget,
       _attemptTimeout = attemptTimeout,
       _retryDelays = retryDelays,
       _networkStatus = networkStatus;

  final DayCardsRemoteDatasource _remote;
  final SharedPreferences _prefs;

  /// Потолок на весь цикл попыток — время, которое видит юзер в мёртвой сети
  /// (captive portal). 10 секунд, потому что сплэш показывает спиннер через
  /// 3с: с индикатором ожидание читается как работа, без него — как зависание.
  final Duration _budget;
  final Duration _attemptTimeout;
  final List<Duration> _retryDelays;
  final NetworkStatus? _networkStatus;

  /// Кэш подневный: календарь листает прошлые дни, а один общий ключ держал
  /// ровно последний загруженный день и на шаг назад уже ничего не помнил.
  ///
  /// Версия в ключе обязательна. Записи хранят `type` карточки строкой, а
  /// маппер разворачивает её через `CardType.values.byName` — то есть стоит
  /// убрать или переименовать тип, и запись прошлой схемы роняет разбор уже
  /// НА КЭШЕ, не доходя до сети. Ровно это и случилось, когда убрали
  /// «вопрос дня»: приложение показывало офлайн-экран при живом интернете.
  /// Меняется набор [CardType] или поля DTO — версия растёт.
  /// v4: запись стала объектом (карточки + имя дня) вместо голого массива
  /// карточек.
  /// v5: добавилось необязательное поле storyUrl. Само оно не ломает разбор
  /// старой записи (null и есть null), но БЕЗ роста версии старый кэш тихо
  /// оставлял бы рассказ дня недоступным до истечения TTL — версия растёт,
  /// хоть парсинг и не падал бы.
  /// v6: Азбука иногда отдаёт storyUrl по HTTP. После его нормализации
  /// старые записи с null всё так же выглядели бы валидными, но не открывали
  /// рассказ, поэтому перезапрашиваем их при следующем входе.
  static const _cachePrefix = 'day_cards_cache_v6:';

  /// Даты в кэше, старые слева. Отдельный индекс, потому что SharedPreferences
  /// не умеет перечислять ключи по префиксу без чтения всего хранилища.
  static const _cacheIndexKey = 'day_cards_cached_dates_v6';

  /// Потолок кэша. Дни хранят распарсенный текст, не разметку, так что это
  /// сотни килобайт — но расти бесконечно ему всё равно незачем.
  static const _maxCachedDays = 60;

  /// Меньше этого остатка попытку не начинаем — она гарантированно не успеет.
  static const _minAttempt = Duration(milliseconds: 500);

  @override
  Future<Result<TodayCards>> getCardsFor(
    DateTime date, {
    bool forceRefresh = false,
  }) async {
    final exact = _readCache(dateKey(date));
    netLog(
      'запрошено ${dateKey(date)}, в кэше '
      '${exact == null ? 'нет этой даты' : 'есть'}, '
      'бюджет ${_budget.inMilliseconds}мс, '
      'попыток максимум ${_retryDelays.length + 1}',
    );
    if (exact != null && !forceRefresh) {
      netLog('кэш за нужную дату — сеть не трогаем');
      return Success(exact);
    }

    if (_networkStatus != null && !await _networkStatus.isOnline()) {
      netLog('сети нет — не запускаем попытки загрузки карточек');
      return Failure(
        AppFailure(
          'Не удалось загрузить карточки дня',
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
      if (left < _minAttempt) {
        netLog('бюджет исчерпан (осталось ${left.inMilliseconds}мс) — стоп');
        break;
      }

      try {
        netLog(
          'попытка ${attempt + 1}, остаток бюджета '
          '${left.inMilliseconds}мс',
        );
        final dto = await _remote.fetch(
          date,
          timeout: left < _attemptTimeout ? left : _attemptTimeout,
        );
        final day = _toEntity(dto);
        try {
          await _writeCache(date, dto);
        } on Exception catch (e) {
          netLog('не удалось записать кэш за ${dateKey(date)}: $e');
        }
        netLog(
          'успех на попытке ${attempt + 1} за '
          '${elapsed.elapsedMilliseconds}мс — отдаём свежие',
        );
        return Success(day);
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

    netLog(
      'всё упало за ${elapsed.elapsedMilliseconds}мс, кэша за '
      '${dateKey(date)} нет — офлайн-экран, kind=${lastKind.name}, '
      'причина: $lastCause',
    );
    return Failure(
      AppFailure(
        'Не удалось загрузить карточки дня',
        kind: lastKind,
        cause: lastCause,
      ),
    );
  }

  static TodayCards _toEntity(DayDto dto) => TodayCards(
    cards: dto.cards.map((c) => c.toEntity()).toList(),
    week: dto.week,
    title: dto.title,
    isFast: dto.isFast,
    storyUrl: dto.storyUrl,
  );

  List<String> _cachedDates() =>
      _prefs.getStringList(_cacheIndexKey) ?? const [];

  Future<void> _writeCache(DateTime date, DayDto dto) async {
    final key = dateKey(date);
    await requirePreferenceWrite(
      _prefs.setString('$_cachePrefix$key', jsonEncode(dto.toJson())),
    );

    // Индекс держим отсортированным по дате: по нему же выбирается stale-день,
    // и «последний» должен значить «самый поздний», а не «записанный позже».
    final dates = {..._cachedDates(), key}.toList()..sort();
    for (final stale in dates.take(
      dates.length > _maxCachedDays ? dates.length - _maxCachedDays : 0,
    )) {
      await requirePreferenceWrite(_prefs.remove('$_cachePrefix$stale'));
    }
    await requirePreferenceWrite(
      _prefs.setStringList(
        _cacheIndexKey,
        dates.length > _maxCachedDays
            ? dates.sublist(dates.length - _maxCachedDays)
            : dates,
      ),
    );
  }

  /// Разбирает запись кэша сразу до entity. Негодная запись — промах кэша,
  /// а не сбой: сходим в сеть и перезапишем.
  ///
  /// Разворот в entity делается ЗДЕСЬ, внутри защищённого блока, и ловится не
  /// только [Exception]. `CardType.values.byName` на неизвестном типе бросает
  /// `ArgumentError` — это `Error`, и он пролетал мимо `on Exception`. Так
  /// удаление «вопроса дня» превратило старую запись кэша в офлайн-экран при
  /// живом интернете: разбор падал, не доходя до сети.
  TodayCards? _readCache(String key) {
    final raw = _prefs.getString('$_cachePrefix$key');
    if (raw == null) return null;
    try {
      return _toEntity(
        DayDto.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      );
    } catch (e) {
      netLog('кэш за $key не разобрался, игнорируем: $e');
      return null;
    }
  }
}
