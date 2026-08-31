# Генератор скриншотов магазина

Веб-инструмент собирает витринные скриншоты из изображений приложения и макета
телефона. Конфигурация и изображения загружаются браузером из `public/`.

## Контент

- `public/config.yaml` — доступные локали и форматы экспорта;
- `public/locales/<locale>/config.yaml` — тексты, тема и порядок слайдов;
- `public/locales/<locale>/*.png` — исходные скриншоты этой локали.

Имя файла в поле `screenshot` — только PNG рядом с локальным `config.yaml`.
Для предпросмотра выбранной локали используйте `?locale=ru`; неизвестная
локаль откроет первую запись из `locales`.

## Запуск

```sh
bun install
bun run dev
```

Откройте <http://localhost:3000>, выберите формат и скачайте отдельный слайд
или ZIP со всеми слайдами.

## CLI для витринных скриншотов

Готовые PNG не хранятся: release workflow строит их в Linux из содержимого
`public/` и передаёт в свой временный каталог. Локально результат текущего
формата можно получить так:

```sh
bun install
bunx playwright install chromium
output_dir=$(mktemp -d)
bun run capture -- --locale ru --format rustore --output-dir "$output_dir"
```

`output_dir` должен существовать и быть пустым. Команда сама собирает Next
перед capture; файлы именуются в порядке YAML, например `01-hero.png`.

## Проверка

```sh
bun test
bun run build
```
