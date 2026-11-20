import '../../../../core/result/result.dart';
import '../entities/day_card.dart';

/// Подсказки «Мудрости дня» для новичка.
abstract interface class WisdomHintRepository {
  /// Открывал ли юзер «Мудрость дня» хоть раз. До этого плитка прыгает.
  Future<Result<bool>> wisdomOpened();

  Future<Result<void>> markWisdomOpened();

  /// Разделы, которые уже представлены крупной плашкой при первом показе.
  Result<Set<CardType>> introducedSections();

  Future<Result<void>> markSectionIntroduced(CardType type);
}
