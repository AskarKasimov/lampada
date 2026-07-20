import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/data/datasources/day_cards_remote_datasource.dart';

void main() {
  late String fixtureHtml;

  String loadFixture(String date) => File(
        'test/features/daily_cards/data/datasources/fixtures/'
        'azbyka_days_$date.html',
      ).readAsStringSync();

  setUpAll(() {
    fixtureHtml = loadFixture('2026-07-19');
  });

  AzbykaDayCardsRemoteDatasource buildDatasource({int statusCode = 200}) {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://azbyka.ru/days/2026-07-19');
      return http.Response(
        fixtureHtml,
        statusCode,
        headers: {'content-type': 'text/html; charset=utf-8'},
      );
    });
    return AzbykaDayCardsRemoteDatasource(client: client);
  }

  test('парсит все 4 карточки дня из реальной страницы', () async {
    final datasource = buildDatasource();
    final cards = await datasource.fetch(
      DateTime(2026, 7, 19),
      timeout: const Duration(seconds: 3),
    );

    expect(
      cards.map((c) => c.type).toSet(),
      {'quote', 'advice', 'basics', 'reading'},
    );

    final quote = cards.firstWhere((c) => c.type == 'quote');
    expect(quote.id, 'quote-2026-07-19');
    expect(
      quote.body,
      'Существом души моей и целью жизни моей должна быть любовь; '
      'всё прочее должно почитаться ничтожным в сравнении с любовью.',
    );
    expect(quote.source, 'св. прав. Иоанн Кронштадтский');

    final advice = cards.firstWhere((c) => c.type == 'advice');
    expect(advice.id, 'advice-2026-07-19');
    expect(advice.source, 'Азбука веры');
    expect(advice.body, contains('Как христианину относиться к приметам?'));
    expect(advice.body.split('\n\n').length, 3);

    final basics = cards.firstWhere((c) => c.type == 'basics');
    expect(basics.id, 'basics-2026-07-19');
    expect(basics.source, 'Азбука веры');
    expect(basics.body, contains('Седмичный богослужебный круг'));
    expect(basics.body.split('\n\n').length, 5);

    final reading = cards.firstWhere((c) => c.type == 'reading');
    expect(reading.id, 'reading-2026-07-19');
    expect(reading.source, 'Азбука веры');
    expect(reading.body, contains('гора из чистого адаманта'));
    expect(reading.body.split('\n\n').length, 2);
  });

  test('не-200 → RemoteFetchException с kind server', () async {
    final datasource = buildDatasource(statusCode: 500);

    await expectLater(
      () => datasource.fetch(
        DateTime(2026, 7, 19),
        timeout: const Duration(seconds: 3),
      ),
      throwsA(
        isA<RemoteFetchException>()
            .having((e) => e.kind, 'kind', FailureKind.server),
      ),
    );
  });

  test('битая разметка → RemoteFetchException с kind unknown', () async {
    final client = MockClient(
      (request) async => http.Response('<html><body></body></html>', 200),
    );
    final datasource = AzbykaDayCardsRemoteDatasource(client: client);

    await expectLater(
      () => datasource.fetch(
        DateTime(2026, 7, 19),
        timeout: const Duration(seconds: 3),
      ),
      throwsA(
        isA<RemoteFetchException>()
            .having((e) => e.kind, 'kind', FailureKind.unknown),
      ),
    );
  });

  test('ответ не пришёл за таймаут → RemoteFetchException с kind network',
      () async {
    final client = MockClient((request) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return http.Response('', 200);
    });
    final datasource = AzbykaDayCardsRemoteDatasource(client: client);

    await expectLater(
      () => datasource.fetch(
        DateTime(2026, 7, 19),
        timeout: const Duration(milliseconds: 10),
      ),
      throwsA(
        isA<RemoteFetchException>()
            .having((e) => e.kind, 'kind', FailureKind.network),
      ),
    );
  });

  test('притча без <p>, голым текстом с <br> — тоже разбирается', () async {
    // 20 июля azbyka.ru отдала «Притчу дня» без единого <p>: текст лежит
    // прямо в .brif, абзацы разделены <br>. Ровно на этом приложение уходило
    // в вечный офлайн.
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://azbyka.ru/days/2026-07-20');
      return http.Response(
        loadFixture('2026-07-20'),
        200,
        headers: {'content-type': 'text/html; charset=utf-8'},
      );
    });
    final datasource = AzbykaDayCardsRemoteDatasource(client: client);

    final cards = await datasource.fetch(
      DateTime(2026, 7, 20),
      timeout: const Duration(seconds: 3),
    );

    expect(
      cards.map((c) => c.type).toSet(),
      {'quote', 'advice', 'basics', 'reading'},
    );

    final reading = cards.firstWhere((c) => c.type == 'reading');
    expect(reading.id, 'reading-2026-07-20');
    expect(reading.body, contains('спросить муху'));
    expect(reading.body, contains('пчелу'));
    // <br> обязаны стать границами абзацев, иначе текст слипается в простыню.
    expect(reading.body.split('\n\n').length, 3);

    // Остальные блоки на этой же странице не должны пострадать.
    final advice = cards.firstWhere((c) => c.type == 'advice');
    expect(advice.body, contains('восточной медицины'));
    final basics = cards.firstWhere((c) => c.type == 'basics');
    expect(basics.body, contains('Тропари и кондаки'));
  });
}
