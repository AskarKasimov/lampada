import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_card.freezed.dart';

/// Порядок значений enum = порядок в «Мудрости дня»: цитата → совет → притча →
/// Евангелие. «Основы» остаются отдельным курсом на главной.
enum CardType { quote, advice, parable, reading, basics }

/// Единица дневного контента: одна карточка — один экран.
@freezed
abstract class DayCard with _$DayCard {
  const factory DayCard({
    required String id,
    required CardType type,
    required String body,

    /// Источник на Азбуке веры (автор/страница).
    required String source,

    /// Машинная ссылка на отрывок (`Jn.10:1-9`) — только у [CardType.reading],
    /// у остальных null. По ней ридер лениво догружает стихи и толкование:
    /// тянуть их вместе с днём значило бы утроить сетевой путь ради экрана,
    /// до которого доходит меньшинство сессий. В [body] при этом лежит
    /// человекочитаемое «Ин.10:1–9».
    String? reference,

    /// Название темы — только у [CardType.basics]. Нужно, чтобы вход в курс
    /// на «Сегодня» говорил, что внутри: до этого блок обещал «Основы веры»
    /// и ничего больше, тогда как чтение рядом честно показывало отрывок.
    String? title,
  }) = _DayCard;
}
