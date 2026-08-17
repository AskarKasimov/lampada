import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lampada/core/network/remote_fetch_exception.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/day_story/data/datasources/day_story_remote_datasource.dart';

AzbykaDayStoryRemoteDatasource _servingHtml(String html, {int status = 200}) =>
    AzbykaDayStoryRemoteDatasource(
      client: MockClient(
        (request) async => http.Response(
          html,
          status,
          headers: {'content-type': 'text/html; charset=utf-8'},
        ),
      ),
    );

void main() {
  group('рассказ о празднике', () {
    test('вытягивает абзацы из .holiday-description .brif', () async {
      final datasource = _servingHtml(
        '<html><body><div class="block holiday-description">'
        '<p class="short-description">Короткая версия снаружи</p>'
        '<div class="brif"><h2>Праздник празднуется …</h2>'
        '<p>Абзац первый.</p><p>Абзац второй.</p></div>'
        '</div></body></html>',
      );

      final dto = await datasource.fetch(
        'https://azbyka.ru/days/holiday',
        timeout: const Duration(seconds: 5),
      );

      expect(dto.paragraphs, ['Абзац первый.', 'Абзац второй.']);
    });

    test(
      'короткая версия .short-description снаружи .brif не попадает',
      () async {
        final datasource = _servingHtml(
          '<html><body><div class="block holiday-description">'
          '<p class="short-description">Короткая версия снаружи</p>'
          '<div class="brif"><p>Полный текст.</p></div>'
          '</div></body></html>',
        );

        final dto = await datasource.fetch(
          'https://azbyka.ru/days/holiday',
          timeout: const Duration(seconds: 5),
        );

        expect(dto.paragraphs, ['Полный текст.']);
      },
    );
  });

  group('рассказ о святом', () {
    test('вытягивает абзацы из .saint-description .brif', () async {
      final datasource = _servingHtml(
        '<html><body><div class="block saint-description">'
        '<div class="brif"><h3>Житие …</h3>'
        '<p>Родился в семье …</p></div>'
        '</div></body></html>',
      );

      final dto = await datasource.fetch(
        'https://azbyka.ru/days/sv-ivanov',
        timeout: const Duration(seconds: 5),
      );

      expect(dto.paragraphs, ['Родился в семье …']);
    });
  });

  test('заголовки секции вырезаются, а не попадают абзацем', () async {
    final datasource = _servingHtml(
      '<html><body><div class="block saint-description"><div class="brif">'
      '<h2>Заголовок</h2><h3>Подзаголовок</h3><p>Текст.</p>'
      '</div></div></body></html>',
    );

    final dto = await datasource.fetch(
      'https://azbyka.ru/days/x',
      timeout: const Duration(seconds: 5),
    );

    expect(dto.paragraphs, ['Текст.']);
  });

  test('сноски [1] вырезаются из середины текста', () async {
    final datasource = _servingHtml(
      '<html><body><div class="block saint-description"><div class="brif">'
      '<p>Событие произошло<sup><a href="#p1">[1]</a></sup> в тот год.</p>'
      '</div></div></body></html>',
    );

    final dto = await datasource.fetch(
      'https://azbyka.ru/days/x',
      timeout: const Duration(seconds: 5),
    );

    expect(dto.paragraphs.single, isNot(contains('[1]')));
    expect(dto.paragraphs.single, 'Событие произошло в тот год.');
  });

  test('<br> внутри абзаца превращается в перевод строки', () async {
    final datasource = _servingHtml(
      '<html><body><div class="block saint-description"><div class="brif">'
      '<p>Строка первая.<br>Строка вторая.</p>'
      '</div></div></body></html>',
    );

    final dto = await datasource.fetch(
      'https://azbyka.ru/days/x',
      timeout: const Duration(seconds: 5),
    );

    expect(dto.paragraphs.single, 'Строка первая.\nСтрока вторая.');
  });

  test(
    'вложенные <li> внутри списка не дублируются как отдельный абзац',
    () async {
      final datasource = _servingHtml(
        '<html><body><div class="block saint-description"><div class="brif">'
        '<ul><li>Пункт один<ul><li>Подпункт</li></ul></li>'
        '<li>Пункт два</li></ul>'
        '</div></div></body></html>',
      );

      final dto = await datasource.fetch(
        'https://azbyka.ru/days/x',
        timeout: const Duration(seconds: 5),
      );

      expect(dto.paragraphs, ['Подпункт', 'Пункт два']);
    },
  );

  test('страница другого шаблона без .brif → unknown, не сбой сети', () async {
    final datasource = _servingHtml(
      '<html><body><article>Пасха в 2027 году: какого числа …</article>'
      '</body></html>',
    );

    expect(
      () => datasource.fetch(
        'https://azbyka.ru/days/prazdnik-pasha',
        timeout: const Duration(seconds: 5),
      ),
      throwsA(
        isA<RemoteFetchException>().having(
          (e) => e.kind,
          'kind',
          FailureKind.unknown,
        ),
      ),
    );
  });

  test('.brif есть, но внутри пусто → unknown', () async {
    final datasource = _servingHtml(
      '<html><body><div class="block saint-description">'
      '<div class="brif"></div></div></body></html>',
    );

    expect(
      () => datasource.fetch(
        'https://azbyka.ru/days/x',
        timeout: const Duration(seconds: 5),
      ),
      throwsA(
        isA<RemoteFetchException>().having(
          (e) => e.kind,
          'kind',
          FailureKind.unknown,
        ),
      ),
    );
  });

  test('сервер вернул не 200 → server', () async {
    final datasource = _servingHtml('упс', status: 500);

    expect(
      () => datasource.fetch(
        'https://azbyka.ru/days/x',
        timeout: const Duration(seconds: 5),
      ),
      throwsA(
        isA<RemoteFetchException>().having(
          (e) => e.kind,
          'kind',
          FailureKind.server,
        ),
      ),
    );
  });

  test('нераспознанная ссылка → unknown', () async {
    final datasource = AzbykaDayStoryRemoteDatasource(
      client: MockClient((request) async => http.Response('', 200)),
    );

    expect(
      () => datasource.fetch('не ссылка', timeout: const Duration(seconds: 5)),
      throwsA(
        isA<RemoteFetchException>().having(
          (e) => e.kind,
          'kind',
          FailureKind.unknown,
        ),
      ),
    );
  });
}
