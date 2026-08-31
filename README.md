# Лампада

«Лампада» — Flutter-приложение для короткой ежедневной православной сессии:
одна единица контента на экран, без лент и дашбордов. Дневной материал приходит
с [Азбуки веры](https://azbyka.ru/).

## Что внутри

У дня три независимых трека:

- **сессия дня**: цитата, совет и притча в полноэкранном просмотрщике;
- **Евангелие дня**: постишный ридер с толкованием Феофилакта Болгарского;
- **«Основы веры»**: личный курс из 365 тем.

Любой трек отмечает день прочитанным. Курс ведёт личный прогресс и не зависит
от выбранной календарной даты. При входе на «Сегодня» приложение открывает
первый непрочитанный раздел; когда всё прочитано — показывает сам день.

## Архитектура

Используем feature-first и строгую Clean Architecture:

```text
presentation → domain ← data
```

- Каждая фича находится в `lib/features/<feature>/` и содержит `domain`,
  `data` и `presentation`. В `lib/core/` попадает только общий код.
- `domain` — чистый Dart: без Flutter, data- и presentation-импортов.
- `data` не импортирует presentation. DTO остаются в data-слое и переходят в
  entity через отдельный mapper.
- UI вызывает use case, не репозиторий. Репозиторий преобразует исключения
  data-слоя в `AppFailure`; границу пересекает `Result<T>`.
- Провайдеры Riverpod находятся в `presentation/providers/`; единственный
  допустимый импорт data из presentation — composition root фичи.
- Entity — `freezed` без JSON, DTO — `freezed` с `fromJson`.

Доменные правила покрываются unit-тестами рядом с use case, UI — widget-тестами
в зеркальной структуре `test/`.

## Локальная разработка

Для iOS требуется Flutter 3.44 или новее. Если Swift Package Manager отключён:

```sh
flutter config --enable-swift-package-manager
```

После изменения Dart-кода выполните:

```sh
dart format .
flutter analyze
flutter test
```

После изменения `freezed`-entity или JSON DTO сначала запустите:

```sh
dart run build_runner build --delete-conflicting-outputs
```

## Контент и локальное состояние

День загружается с `azbyka.ru/days/{дата}`. Кэш привязан к запрошенной дате;
данные за другую дату не подставляются. У загрузки общий бюджет 10 секунд, до
трёх попыток и без повторов при ошибке парсинга. Логи сети доступны только в
debug-сборке.

`SharedPreferences` хранит дневной прогресс, посещённые дни, закладки и личный
прогресс курса. Толкования и рассказы дня загружаются лениво. Напоминания
планируются на неделю вперёд и только для непрочитанных разделов.

Известные ограничения:

- маркеры постов и праздников в недельной полоске пока не выводятся;
- серия дней уже считается, но в интерфейсе не показана;
- кэш чтения пока не ограничен по размеру;
- уведомления Android требуют отдельной проверки `POST_NOTIFICATIONS`.

## Нативная часть и ассеты

В release-варианте Android нужно разрешение `android.permission.INTERNET` в
`android/app/src/main/AndroidManifest.xml`: debug/profile-манифесты release не
покрывают.

Иконка использует два исходника:

- `assets/icon/icon_foreground.png` — прозрачный foreground Android adaptive icon;
- `assets/icon/icon_ios.png` — непрозрачная подложка iOS.

Перед обновлением iOS-версии запустите
`dart run tool/make_ios_icon.dart`, затем `dart run flutter_launcher_icons`.
Скрипт композитит прозрачный Android-исходник на фон: одного
`remove_alpha_ios` недостаточно, поскольку генератор не очищает RGB в
прозрачных пикселях. После генерации проверьте, что
`ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` в
`ios/Runner.xcodeproj/project.pbxproj` остаётся `YES`.

После изменения Android/iOS-конфигурации, splash-экрана или иконок вручную
проверьте Android release/profile и iOS release: холодный старт в светлой и
тёмной теме, сеть и отрисовку иконки.

## Вклад и релизы

Правила веток, коммитов, проверок и выпуска описаны в
[CONTRIBUTING.md](CONTRIBUTING.md). Push тега `vX.Y.Z` запускает отправку
релиза в RuStore; workflow берёт заметки из соответствующего раздела
`CHANGELOG.md`.
