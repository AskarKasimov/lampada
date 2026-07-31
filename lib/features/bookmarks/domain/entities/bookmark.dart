import 'package:freezed_annotation/freezed_annotation.dart';

part 'bookmark.freezed.dart';

/// Что именно сохранено. Своё перечисление, а не [CardType] из daily_cards:
/// в копилку попадают и стихи с толкованиями, у которых карточки дня нет,
/// и тянуть чужой домен ради трёх значений незачем.
enum BookmarkKind { card, verse, interpretation }

/// Сохранённая единица смысла. [id] стабилен и собирается из происхождения
/// (`quote-2026-07-28`, `verse-Jn.10:1`) — по нему же работает переключение
/// «сохранено/не сохранено», поэтому одна и та же карточка не двоится.
@freezed
abstract class Bookmark with _$Bookmark {
  const factory Bookmark({
    required String id,
    required BookmarkKind kind,
    required String text,

    /// Автор цитаты или ссылка отрывка — то, что показывается подписью.
    required String source,

    /// Подпись типа для списка: «Цитата дня», «Стих», «Толкование».
    required String label,
    required DateTime savedAt,
  }) = _Bookmark;
}
