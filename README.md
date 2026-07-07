# Лампада

Приложение для новоначального православного: одна дневная сессия 3–5 минут,
одна карточка контента на весь экран. Порядок внутри дня: цитата → совет →
основы → чтение. Контент — дневные фиды Азбуки веры.

iOS — первый приоритет, Android — второй.

## Правила архитектуры

Строгая clean architecture, feature-first. Нарушение любого правила — блокер ревью.

### 1. Feature-first

Каждая возможность — папка `lib/features/<фича>/` со слоями `domain`, `data`,
`presentation`. Общее — в `lib/core/`. Эталон: `lib/features/daily_cards/`.

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
Исключения гасятся в repository impl:
`lib/features/daily_cards/data/repositories/day_cards_repository_impl.dart`.

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

Скаффолд. Мок-контент. Реальный парсинг Азбуки, пуши, календарь — следующие
итерации.
