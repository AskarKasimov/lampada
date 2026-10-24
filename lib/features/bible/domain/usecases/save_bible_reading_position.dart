import '../../../../core/result/result.dart';
import '../entities/bible_reading_position.dart';
import '../repositories/bible_repository.dart';

class SaveBibleReadingPosition {
  const SaveBibleReadingPosition(this._repository);

  final BibleRepository _repository;

  Future<Result<void>> call(BibleReadingPosition position) =>
      _repository.saveReadingPosition(position);
}
