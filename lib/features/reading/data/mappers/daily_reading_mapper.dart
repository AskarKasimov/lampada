import '../../domain/entities/daily_reading.dart';
import '../dto/daily_reading_dto.dart';

extension VerseDtoMapper on VerseDto {
  Verse toEntity() => Verse(
    number: number,
    chapter: chapter,
    text: text,
    interpretation: interpretation,
    interpretationRange: interpretationRange,
  );
}

extension DailyReadingDtoMapper on DailyReadingDto {
  DailyReading toEntity() => DailyReading(
    label: label,
    verses: verses.map((v) => v.toEntity()).toList(),
    interpretationAuthor: interpretationAuthor,
  );
}
