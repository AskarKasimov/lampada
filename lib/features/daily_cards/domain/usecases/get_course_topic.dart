import '../../../../core/result/result.dart';
import '../course_calendar.dart';
import '../entities/day_card.dart';
import '../entities/today_cards.dart';
import '../repositories/course_progress_repository.dart';
import '../repositories/day_cards_repository.dart';

/// Карточка «Основы» для текущей темы курса, а не для сегодняшней даты.
///
/// Юзер, поставивший приложение в июле, раньше встречал «Тему 209» — курс
/// начинался с середины и читался как случайный факт. Теперь он начинает с
/// первой темы; следующая открывается после прочтения текущей и нового дня.
class GetCourseTopic {
  const GetCourseTopic(this._progress, this._cards);

  final CourseProgressRepository _progress;
  final DayCardsRepository _cards;

  Future<Result<DayCard>> call() async {
    final topicResult = await _progress.currentTopic();
    switch (topicResult) {
      case Failure(failure: final f):
        return Failure(f);
      case Success(value: final topic):
        return forTopic(topic);
    }
  }

  /// Карточка «Основы» для явно запрошенной темы курса.
  Future<Result<DayCard>> forTopic(int topic) => _topicCard(topic);

  Future<Result<DayCard>> _topicCard(int topic) async {
    // Тема живёт на странице дня, у которого день года равен её номеру —
    // отдельного эндпоинта по номеру у Азбуки нет. Идём через тот же
    // репозиторий дня: кэш, ретраи и бюджет уже там.
    final dayResult = await _cards.getCardsFor(dateForCourseTopic(topic));

    // Типизированный switch, а не `as Success`: сырой каст без параметра типа
    // делает `.value` динамическим, и дальше extension-методы (`firstOrNull`)
    // перестают резолвиться — анализатор при этом молчит, а падает уже
    // в рантайме.
    switch (dayResult) {
      case Failure(failure: final f):
        return Failure(f);
      case Success(value: final TodayCards day):
        // Fallback-кэш относится к другой дате. Выдать его за тему [topic]
        // означало бы незаметно подменить личный курс случайными «Основами».
        // Провайдер оставит обычную карточку дня, пока тема не загрузится.
        if (day.staleDate != null) {
          return Failure(
            AppFailure(
              'Не удалось загрузить тему $topic',
              kind: FailureKind.unknown,
            ),
          );
        }
        final basics = day.cards
            .where((c) => c.type == CardType.basics)
            .firstOrNull;
        if (basics == null) {
          return Failure(
            AppFailure(
              'У темы $topic нет раздела «Основы»',
              kind: FailureKind.unknown,
            ),
          );
        }
        // id завязываем на номер темы, а не на дату: иначе закладка на тему
        // выглядела бы закладкой на чужой день.
        return Success(basics.copyWith(id: 'basics-topic-$topic'));
    }
  }
}
