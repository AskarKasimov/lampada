import 'package:freezed_annotation/freezed_annotation.dart';

part 'bookmark_dto.freezed.dart';
part 'bookmark_dto.g.dart';

@freezed
abstract class BookmarkDto with _$BookmarkDto {
  const factory BookmarkDto({
    required String id,

    /// Строковое имя BookmarkKind: card | verse | interpretation | story.
    required String kind,
    required String text,
    required String source,
    required String label,

    /// ISO-8601. Хранится строкой, чтобы JSON оставался человекочитаемым
    /// при отладке prefs.
    required String savedAt,
  }) = _BookmarkDto;

  factory BookmarkDto.fromJson(Map<String, dynamic> json) =>
      _$BookmarkDtoFromJson(json);
}
