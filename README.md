# Лампада

Приложение для новоначального православного: одна дневная сессия 3–5 минут,
одна карточка контента на весь экран. Порядок внутри дня: цитата → совет →
основы → чтение. Контент — дневные фиды Азбуки веры.

iOS — первый приоритет, Android — второй.

## Правила архитектуры

Строгая clean architecture, feature-first. Нарушение любого правила — блокер ревью.

### 1. Feature-first

Каждая возможность — папка `lib/features/<фича>/` со слоями `domain`, `data`,
`presentation`. Общее — в `lib/core/` (тема — `core/theme/`, переиспользуемые
виджеты — `core/widgets/`: `AppPrimaryButton`, `AppPillBadge`, `AppLinkButton`).
Эталон: `lib/features/daily_cards/`.

### 2. Направление зависимостей: presentation → domain ← data

- `domain` не импортирует `data`, `presentation` и Flutter. Только чистый Dart
  (+ `freezed_annotation`). Пример: `lib/features/daily_cards/domain/entities/day_card.dart`.
- `data` не импортирует `presentation`. DTO не покидает data-слой — наружу
  только entity через mapper: `lib/features/daily_cards/data/mappers/day_card_mapper.dart`.
- `presentation` не импортирует `data`, кроме ОДНОГО файла — composition root
  фичи: `lib/features/daily_cards/presentation/providers/providers.dart`.

### 3. UI вызывает usecase, не репозиторий

Пример: `lib/features/daily_cards/domain/usecases/get_today_cards.dart`.
Вся доменная логика (например, фиксированный порядок карточек) живёт в usecase
и покрыта тестом: `test/features/daily_cards/domain/usecases/get_today_cards_test.dart`.

### 4. Ошибки — через Result, не исключения

Usecase и репозиторий возвращают `Result<T>` (`lib/core/result/result.dart`).
Репозиторий — единственное место, где исключения data-слоя гасятся и
превращаются в `Failure`. Для удалённых источников заводится отдельный
datasource, репозиторий сверху добавляет кэш/фоллбэк:
`lib/features/daily_cards/data/datasources/day_cards_remote_datasource.dart` +
`lib/features/daily_cards/data/repositories/azbyka_day_cards_repository.dart`.
Для локального стораджа (prefs) отдельный datasource не нужен — репозиторий
обращается к `SharedPreferences` напрямую:
`lib/features/daily_cards/data/repositories/prefs_day_progress_repository.dart`.

### 5. Riverpod

Провайдеры — в `presentation/providers/` фичи. Корень — `ProviderScope`
(`lib/main.dart`). В тестах зависимости подменяются через overrides.

### 6. Модели

Entity — freezed без JSON (`domain/entities/`). DTO — freezed + `fromJson`
(`data/dto/`). После правки моделей:
`dart run build_runner build --delete-conflicting-outputs`.

### 7. Продуктовый принцип в коде

Одна единица контента на экран. Никаких дашбордов, лент и «стен текста».
Эталон: `lib/features/daily_cards/presentation/screens/daily_card_screen.dart`.

## Команды

- `flutter run` — запуск
- `flutter test` — тесты
- `flutter analyze` — статический анализ
- `dart run build_runner build --delete-conflicting-outputs` — кодогенерация

## Статус

Рабочий MVP на iOS. Контент — реальный скрейпинг `azbyka.ru/days/{дата}`
(`AzbykaDayCardsRemoteDatasource`), с кэшем последнего успешного набора
карточек в `SharedPreferences` и фоллбэком на кэш при сетевой ошибке.
Прогресс дня и серия (streak) — тоже в `SharedPreferences`. Светлая/тёмная
тема с переключателем на Home. Общий UI-кит вынесен в `lib/core/widgets/`.

Загрузка дня укладывается в жёсткий бюджет 7 секунд: до трёх попыток с
таймаутом 3 секунды и паузами в секунду, причём таймаут каждой попытки режется
остатком бюджета. Сетевые сбои и не-200 ретраятся, изменившаяся вёрстка — нет
(повтор всё равно упадёт). Если всё упало, а кэш есть — показываются карточки
из кэша с пометкой «Офлайн · карточки за <дату>» и кнопкой «Обновить». Если
кэша нет — Home показывает офлайн-состояние с разным текстом для «нет сети» и
«azbyka.ru недоступна»: советовать включить Wi-Fi, когда лёг сам источник,
вредно. Возврат в приложение из фона перезапрашивает карточки сам.

Сессия на карточках за другой день прогресс не двигает: ни `readTypes`, ни
серию. Сегодняшний контент юзеру не показывали — значит день не пройден, и
экран завершения честно говорит, за какое число были карточки, вместо «огонёк
на сегодня зажжён».

Ещё не сделано: пуши-напоминания, календарь/история прошлых дней,
Android — не тестировался.
