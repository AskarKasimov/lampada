# Генератор скриншотов

Next.js-инструмент для подготовки витринных скриншотов «Лампады». Он не
копирует и не обрабатывает контент на сервере: браузер читает конфигурацию и
изображения из `public/`.

## Контент

- `public/config.yaml` задаёт доступные локали и размеры для всех магазинов.
- `public/locales/<locale>/config.yaml` задаёт слайды этой локали.
- Исходный PNG лежит рядом с локальным конфигом; в `screenshot` указывайте
  только имя этого PNG, без пути.
- Не возвращайте подготовительные скрипты, API-маршруты или второй источник
  текстов/форматов в коде: `public` — единственный источник контента.

## Код

- `src/app/page.tsx` отвечает только за предпросмотр и экспорт.
- Проверку и загрузку YAML держите в `src/lib/screenshot_config.ts` и
  `src/lib/screenshot_content.ts`; новые правила конфигурации покрывайте
  Bun-тестом рядом.
- Комментарии оставляйте для инвариантов, ограничений экспорта и решений,
  которые нельзя понять из кода; пишите их кратко, на русском.

## Проверка

После изменения TypeScript, YAML-конфигурации или логики экспорта выполните:

```sh
bun test
bun run build
git diff --check
```

Не меняйте файлы верхнего Flutter-проекта без явной причины задачи. Сохраняйте
чужие изменения и добавляйте в коммит только перечисленные пути.

<!-- BEGIN:nextjs-agent-rules -->

# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->
