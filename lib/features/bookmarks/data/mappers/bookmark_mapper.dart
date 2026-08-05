import '../../domain/entities/bookmark.dart';
import '../dto/bookmark_dto.dart';

extension BookmarkDtoMapper on BookmarkDto {
  /// Бросает на неизвестном kind или битой дате — репозиторий переводит
  /// исключение в Failure.
  Bookmark toEntity() => Bookmark(
        id: id,
        kind: BookmarkKind.values.byName(kind),
        text: text,
        source: source,
        label: label,
        savedAt: DateTime.parse(savedAt),
      );
}

extension BookmarkMapper on Bookmark {
  BookmarkDto toDto() => BookmarkDto(
        id: id,
        kind: kind.name,
        text: text,
        source: source,
        label: label,
        savedAt: savedAt.toIso8601String(),
      );
}
