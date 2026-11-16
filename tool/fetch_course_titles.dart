import 'dart:io';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

/// Собирает названия всех тем курса «Основы веры» для оглавления читалки.
///
/// Тема N лежит на Азбуке на N-м дне 2026 года (см. `course_calendar.dart`),
/// название стоит в `#osnovy p strong`. Отдельного списка тем у Азбуки нет,
/// поэтому обходим 365 страниц дня с паузой и пишем Dart-константу:
/// оглавление открывается без сети и без 365 запросов из приложения.
///
/// Запуск: `dart run tool/fetch_course_titles.dart`.
Future<void> main() async {
  const target = 'lib/features/daily_cards/domain/course_topic_titles.dart';
  final client = http.Client();
  final titles = <String>[];
  try {
    for (var number = 1; number <= 365; number++) {
      final date = DateTime(2026, 1, number);
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      final title = await _titleOf(client, key, number);
      titles.add(title);
      stdout.writeln('$number\t$title');
      // Не нагружаем Азбуку: это разовый сбор, а не загрузка приложения.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  } finally {
    client.close();
  }

  final buffer = StringBuffer()
    ..writeln(
      '// Сгенерировано tool/fetch_course_titles.dart, не править руками.',
    )
    ..writeln()
    ..writeln(
      '/// Названия тем курса «Основы веры» по порядку: индекс 0 — Тема 1.',
    )
    ..writeln('/// Сверены с Азбукой ${_today()}.')
    ..writeln('const courseTopicTitles = <String>[');
  for (final title in titles) {
    buffer.writeln(
      "  '${title.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}',",
    );
  }
  buffer.writeln('];');
  File(target).writeAsStringSync(buffer.toString());
  stdout.writeln('Записано ${titles.length} тем в $target');
}

Future<String> _titleOf(http.Client client, String key, int number) async {
  for (var attempt = 1; ; attempt++) {
    try {
      final response = await client
          .get(Uri.parse('https://azbyka.ru/days/$key'))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw HttpException('ответ ${response.statusCode}');
      }
      final doc = html_parser.parse(response.body);
      // Обычно название в <strong>, но изредка в <b> (Тема 364).
      final strong = doc.querySelector('#osnovy p strong, #osnovy p b');
      // Азбука вкладывает <p><p>, и первый абзац блока пустой: номер темы
      // стоит в том абзаце, где само название.
      final heading = strong?.parent?.text ?? '';
      final title = strong?.text
          .replaceAll('\u00a0', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          // Изредка номер темы попадает внутрь выделения (Тема 15), а
          // заголовок обрывается двоеточием перед списком (Тема 114).
          .replaceFirst(RegExp(r'^Тема \d+\.\s*'), '')
          .replaceFirst(RegExp(r'\s*:$'), '');
      if (title == null || title.isEmpty) {
        throw FormatException('нет названия темы на $key');
      }
      // Номер в абзаце должен совпасть с днём года, иначе сдвинулся календарь.
      if (!heading.contains('Тема $number.')) {
        throw FormatException('на $key не Тема $number: «$heading»');
      }
      // Точка после названия в оглавлении лишняя, а «..» у Азбуки значит
      // многоточие («Но ведь Библию много раз переписывали..»).
      if (title.endsWith('..')) {
        return '${title.replaceFirst(RegExp(r'\.+$'), '')}…';
      }
      return title.endsWith('.') ? title.substring(0, title.length - 1) : title;
    } on Exception catch (e) {
      if (attempt >= 3) rethrow;
      stderr.writeln('$key: $e, повтор');
      await Future<void>.delayed(Duration(seconds: 2 * attempt));
    }
  }
}

String _today() {
  final now = DateTime.now();
  return '${now.day.toString().padLeft(2, '0')}.'
      '${now.month.toString().padLeft(2, '0')}.${now.year}';
}
