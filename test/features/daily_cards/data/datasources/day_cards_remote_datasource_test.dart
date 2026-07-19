import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lampada/features/daily_cards/data/datasources/day_cards_remote_datasource.dart';

void main() {
  late String fixtureHtml;

  setUpAll(() {
    fixtureHtml = File(
      'test/features/daily_cards/data/datasources/fixtures/azbyka_days_2026-07-19.html',
    ).readAsStringSync();
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
    final cards = await datasource.fetch(DateTime(2026, 7, 19));

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

  test('бросает HttpException при не-200 ответе', () async {
    final datasource = buildDatasource(statusCode: 500);
    expect(
      () => datasource.fetch(DateTime(2026, 7, 19)),
      throwsA(isA<HttpException>()),
    );
  });
}
