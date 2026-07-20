import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/data/datasources/day_cards_remote_datasource.dart';
import 'package:lampada/features/daily_cards/data/dto/day_card_dto.dart';

/// Страница формы azbyka.ru, но с подставным содержимым.
///
/// Ассерты на живые цитаты («гора из чистого адаманта») проверяли бы, что
/// написала Азбука в конкретный день, а не что делает наш парсер, и намертво
/// привязывали бы тесты к фикстуре: обновить её нельзя, не переписав ожидания.
/// Маркеры вместо контента разрывают эту связь — видно ровно отображение
/// «блок разметки → поле карточки».
String _page({
  String quoteBody = 'QUOTE',
  String quoteAuthorHtml = '<a href="/x">AUTHOR</a>',
  String questionHtml =
      "<a class='az-qod-link' href='https://azbyka.ru/vopros/x/'>QUESTION</a>",
  String adviceHtml = '<p>ADVICE</p>',
  String basicsHtml = '<p>BASICS</p>',
  String parableHtml = '<p>PARABLE</p>',
}) =>
    '''
<html><body>
  <div class="widget quote-of-day">
    <div class="box">
      <p>$quoteBody</p>
      <p>$quoteAuthorHtml</p>
    </div>
  </div>
  <div class="widget">
    <div class="widget-title">Вопрос дня</div>
    <div class="box">$questionHtml</div>
  </div>
  <div id="sovet" class="block info advice">
    <h2>Практический совет</h2>
    $adviceHtml
  </div>
  <div id="osnovy" class="block info advice">
    <h2>Основы православия</h2>
    $basicsHtml
  </div>
  <div id="pritcha" class="block info">
    <h2>Притча дня</h2>
    <div class="brif">$parableHtml</div>
  </div>
</body></html>
''';

const _timeout = Duration(seconds: 3);
final _date = DateTime(2026, 7, 19);

AzbykaDayCardsRemoteDatasource _datasourceServing(
  String html, {
  int statusCode = 200,
  String expectUrl = 'https://azbyka.ru/days/2026-07-19',
}) {
  final client = MockClient((request) async {
    expect(request.url.toString(), expectUrl);
    return http.Response(
      html,
      statusCode,
      headers: {'content-type': 'text/html; charset=utf-8'},
    );
  });
  return AzbykaDayCardsRemoteDatasource(client: client);
}

Future<List<DayCardDto>> _fetch(
  AzbykaDayCardsRemoteDatasource datasource, [
  DateTime? date,
]) =>
    datasource.fetch(date ?? _date, timeout: _timeout);

DayCardDto _cardOfType(List<DayCardDto> cards, String type) =>
    cards.firstWhere((c) => c.type == type);

String _loadFixture(String date) => File(
      'test/features/daily_cards/data/datasources/fixtures/'
      'azbyka_days_$date.html',
    ).readAsStringSync();

void main() {
  group('отображение блоков разметки в карточки', () {
    test('каждый блок попадает в свой тип карточки', () async {
      final cards = await _fetch(
        _datasourceServing(
          _page(
            quoteBody: 'ЦИТАТА',
            questionHtml:
                "<a class='az-qod-link' href='https://azbyka.ru/vopros/x/'>ВОПРОС</a>",
            adviceHtml: '<p>СОВЕТ</p>',
            basicsHtml: '<p>ОСНОВЫ</p>',
            parableHtml: '<p>ПРИТЧА</p>',
          ),
        ),
      );

      expect(cards.map((c) => c.type).toList(),
          ['quote', 'question', 'advice', 'basics', 'reading']);
      expect(_cardOfType(cards, 'quote').body, 'ЦИТАТА');
      expect(_cardOfType(cards, 'question').body, 'ВОПРОС');
      expect(_cardOfType(cards, 'advice').body, 'СОВЕТ');
      expect(_cardOfType(cards, 'basics').body, 'ОСНОВЫ');
      expect(_cardOfType(cards, 'reading').body, 'ПРИТЧА');
    });

    test('id складывается из типа и запрошенной даты', () async {
      final cards = await _fetch(_datasourceServing(_page()));

      expect(cards.map((c) => c.id).toSet(), {
        'quote-2026-07-19',
        'question-2026-07-19',
        'advice-2026-07-19',
        'basics-2026-07-19',
        'reading-2026-07-19',
      });
    });

    test('автор цитаты становится источником карточки', () async {
      final cards = await _fetch(
        _datasourceServing(
          _page(quoteAuthorHtml: '<a href="/x">НЕКИЙ АВТОР</a>'),
        ),
      );

      expect(_cardOfType(cards, 'quote').source, 'НЕКИЙ АВТОР');
    });

    test('без ссылки на автора источник цитаты — «Азбука веры»', () async {
      final cards =
          await _fetch(_datasourceServing(_page(quoteAuthorHtml: '')));

      expect(_cardOfType(cards, 'quote').source, 'Азбука веры');
    });

    test('у остальных карточек источник всегда «Азбука веры»', () async {
      final cards = await _fetch(_datasourceServing(_page()));

      for (final type in ['question', 'advice', 'basics', 'reading']) {
        expect(_cardOfType(cards, type).source, 'Азбука веры');
      }
    });
  });

  group('вопрос дня', () {
    test('текст вопроса — это текст ссылки az-qod-link', () async {
      final cards = await _fetch(
        _datasourceServing(
          _page(
            questionHtml: "<a class='az-qod-link' href='https://azbyka.ru/x'>"
                'В чём смысл поста?</a>',
          ),
        ),
      );

      expect(_cardOfType(cards, 'question').body, 'В чём смысл поста?');
    });

    test('блока нет вовсе → RemoteFetchException с kind unknown', () async {
      await expectLater(
        () => _fetch(_datasourceServing(_page(questionHtml: ''))),
        throwsA(isA<RemoteFetchException>()
            .having((e) => e.kind, 'kind', FailureKind.unknown)),
      );
    });
  });

  group('две формы вёрстки секции', () {
    test('абзацы в <p> склеиваются через пустую строку', () async {
      final cards = await _fetch(
        _datasourceServing(
          _page(adviceHtml: '<p>ПЕРВЫЙ</p><p>ВТОРОЙ</p><p>ТРЕТИЙ</p>'),
        ),
      );

      expect(_cardOfType(cards, 'advice').body, 'ПЕРВЫЙ\n\nВТОРОЙ\n\nТРЕТИЙ');
    });

    test('голый текст с <br> тоже разбивается на абзацы', () async {
      // Azbyka отдаёт секции то так, то эдак. Именно этот вариант уводил
      // приложение в вечный офлайн-экран при живом интернете.
      final cards = await _fetch(
        _datasourceServing(
          _page(parableHtml: 'ПЕРВЫЙ<br>ВТОРОЙ<br>ТРЕТИЙ'),
        ),
      );

      expect(_cardOfType(cards, 'reading').body, 'ПЕРВЫЙ\n\nВТОРОЙ\n\nТРЕТИЙ');
    });

    test('<br> внутри <p> тоже даёт перенос, а не слипшийся текст', () async {
      final cards = await _fetch(
        _datasourceServing(_page(adviceHtml: '<p>СТРОКА<br>ЕЩЁ</p>')),
      );

      expect(_cardOfType(cards, 'advice').body, 'СТРОКА\nЕЩЁ');
    });

    test('заголовок секции не утекает в текст карточки', () async {
      // Важно именно для формы без <p>: там контентом становится весь
      // контейнер целиком, вместе с <h2>, если его не выкинуть.
      final cards = await _fetch(
        _datasourceServing(_page(adviceHtml: 'ГОЛЫЙ ТЕКСТ')),
      );

      final advice = _cardOfType(cards, 'advice');
      expect(advice.body, 'ГОЛЫЙ ТЕКСТ');
      expect(advice.body, isNot(contains('Практический совет')));
    });
  });

  group('реальные страницы azbyka', () {
    // Дымовой тест: селекторы всё ещё цепляются за живую вёрстку. Содержимое
    // тут намеренно не проверяется — оно принадлежит Азбуке и меняется каждый
    // день. 19 июля секции размечены через <p>, 20 июля притча пришла голым
    // текстом с <br>: два дня закрывают обе формы на настоящей разметке.
    for (final date in ['2026-07-19', '2026-07-20']) {
      test('$date разбирается в пять непустых карточек', () async {
        final cards = await _fetch(
          _datasourceServing(
            _loadFixture(date),
            expectUrl: 'https://azbyka.ru/days/$date',
          ),
          DateTime.parse(date),
        );

        expect(cards.map((c) => c.type).toList(),
            ['quote', 'question', 'advice', 'basics', 'reading']);
        for (final card in cards) {
          expect(card.id, '${card.type}-$date');
          expect(card.body.trim(), isNotEmpty, reason: 'пустая ${card.type}');
          expect(card.source.trim(), isNotEmpty);
        }
      });
    }

    test('20 июля притча разбита на абзацы, а не слиплась в простыню',
        () async {
      final cards = await _fetch(
        _datasourceServing(
          _loadFixture('2026-07-20'),
          expectUrl: 'https://azbyka.ru/days/2026-07-20',
        ),
        DateTime(2026, 7, 20),
      );

      expect(
        _cardOfType(cards, 'reading').body.split('\n\n').length,
        greaterThan(1),
      );
    });
  });

  group('ошибки', () {
    test('не-200 → RemoteFetchException с kind server', () async {
      await expectLater(
        () => _fetch(_datasourceServing(_page(), statusCode: 500)),
        throwsA(isA<RemoteFetchException>()
            .having((e) => e.kind, 'kind', FailureKind.server)),
      );
    });

    test('блока нет вовсе → RemoteFetchException с kind unknown', () async {
      await expectLater(
        () => _fetch(_datasourceServing('<html><body></body></html>')),
        throwsA(isA<RemoteFetchException>()
            .having((e) => e.kind, 'kind', FailureKind.unknown)),
      );
    });

    test('блок на месте, но пустой → тоже unknown', () async {
      await expectLater(
        () => _fetch(_datasourceServing(_page(parableHtml: '   '))),
        throwsA(isA<RemoteFetchException>()
            .having((e) => e.kind, 'kind', FailureKind.unknown)),
      );
    });

    test('ответ не пришёл за таймаут → kind network', () async {
      final client = MockClient((request) async {
        await Future<void>.delayed(const Duration(seconds: 1));
        return http.Response('', 200);
      });

      await expectLater(
        () => AzbykaDayCardsRemoteDatasource(client: client)
            .fetch(_date, timeout: const Duration(milliseconds: 10)),
        throwsA(isA<RemoteFetchException>()
            .having((e) => e.kind, 'kind', FailureKind.network)),
      );
    });
  });
}
