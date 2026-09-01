# Вклад в «Лампаду»

## Ветки и pull request

- `master` содержит последний стабильный релиз.
- Постоянной интеграционной ветки нет. Обычная работа идёт в
  `feature/<краткое-имя>`, `fix/<краткое-имя>` или
  `docs/<краткое-имя>` от `master`:
  `рабочая ветка → PR → master → tag vX.Y.Z`.

В `master` не делайте прямой push без явного согласования. Для обычного
изменения нужны PR, успешный CI и ревью (при необходимости). Не используйте
force-push, удаление `master` или переписывание её истории без явного
согласования.

Перед merge убедитесь, что ветка содержит только изменения задачи, а на её
итоговом состоянии выполнены нужные проверки.

## Изменения и проверки

Делайте минимальное изменение в существующем стиле. Сначала добавьте падающий
тест для новой доменной логики или бага, затем исправляйте реализацию. Нативные
настройки, ассеты и документацию можно менять без теста.

После изменения Dart-кода обязательно выполните:

```sh
dart format .
flutter analyze
flutter test
```

`flutter analyze` должен завершиться без issues, а `flutter test` — без
упавших тестов. После изменения `freezed`-entity или JSON DTO сначала
запустите `dart run build_runner build --delete-conflicting-outputs`.

Перед передачей результата выполните:

```sh
git diff --check
```

## Коммиты

Добавляйте в индекс только файлы задачи.
Сообщения коммитов пишите по-английски в формате Conventional Commits:

```text
feat(scope): add daily reading
fix: preserve unread progress
docs: clarify release process
```

Subject — до 50 символов; тело добавляйте, только когда причина не очевидна из
subject. Не добавляйте AI-трейлеры, например `Co-Authored-By`.

## Релиз

1. Если версия и changelog ещё не обновлены, создайте от `master` обычную
   короткую ветку, например `chore/release-<версия>`.
2. Обновите `version` в `pubspec.yaml`: `versionName` совпадает с будущим
   тегом без `v`, а `versionCode` выше уже выпущенного в сторы. Добавьте
   непустой раздел текущей версии в `CHANGELOG.md`.
3. Влейте этот PR в `master` после CI и review.
4. Создайте и отправьте тег `vX.Y.Z` на текущем merge-коммите в `master`.

Push тега запускает workflow **«Stores: отправить на модерацию»**. Он без
production-секретов проверяет tag, версию, форматирование, анализ и тесты, а
затем в отдельных jobs собирает Android AAB и iOS IPA. AAB отправляется на
модерацию RuStore с ручной публикацией; IPA, release notes и скриншоты
загружаются в App Store Connect и автоматически отправляются в App Review.
После одобрения обе версии публикуются вручную.

Для каждой версии нужен непустой раздел changelog вида
`## [X.Y.Z] - YYYY-MM-DD`: до 5 000 символов для RuStore и до 4 000 для App
Store. Не включайте туда секреты и техническую информацию, т.к. всё написанное
отправляется в сторы. Для повтора вручную выберите target `rustore`, передайте
ID уже созданного черновика, либо выберите target `appstore` для повторной
iOS-отправки.

Скриншоты workflow берёт из `aso-collection/generator/public/`. После
изменения экранов проверьте их локально из `aso-collection/generator`:

```sh
bun run capture -- --locale ru --format rustore --output-dir <пустой-каталог>
bun run capture -- --locale ru --format app-store-6-9 --output-dir <пустой-каталог>
bun run capture -- --locale ru --format app-store-6-5 --output-dir <пустой-каталог>
```

Секреты и подписи хранятся только в GitHub Environments, а не в репозитории.
Создайте `rustore-production` с текущими Android/RuStore секретами и
`appstore-production` с iOS/AppStore.
