import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lampada/core/network/remote_fetch_exception.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/data/datasources/day_cards_remote_datasource.dart';
import 'package:lampada/features/daily_cards/data/dto/day_card_dto.dart';
import 'package:lampada/features/daily_cards/data/dto/day_dto.dart';

/// Страница формы azbyka.ru с подставным содержимым вместо реальных цитат —
/// так тест проверяет отображение «блок разметки → поле карточки», а не то,
/// что Азбука опубликовала в конкретный день.
String _page({
  String quoteBody = 'QUOTE',
  String quoteAuthorHtml = '<a href="/x">AUTHOR</a>',
  String adviceHtml = '<p>ADVICE</p>',
  String basicsHtml = '<p>BASICS</p>',
  String? readingsHtml,
  String? parableHtml,
  String? headerHtml,
}) =>
    '''
<html><body>
  ${headerHtml ?? ''}
  <div class="widget quote-of-day">
    <div class="box">
      <p>$quoteBody</p>
      <p>$quoteAuthorHtml</p>
    </div>
  </div>
  <div id="sovet" class="block info advice">
    <h2>Практический совет</h2>
    $adviceHtml
  </div>
  <div id="osnovy" class="block info advice">
    <h2>Основы православия</h2>
    $basicsHtml
  </div>
  <div id="chteniya" class="block readings">
    <h2>Чтения Священного Писания</h2>
    <div class="readings-inner"><div class="readings-text">${readingsHtml ?? _liturgyOnlyReadings}</div></div>
  </div>
  ${parableHtml == null ? '' : '''
  <div id="pritcha" class="block info">
    <h2><a href="/pritchi">Притча</a> дня</h2>
    <div class="brif">$parableHtml</div>
  </div>
  '''}
</body></html>
''';

String _bibref(String slug, String label) =>
    '<a class="bibref" href="https://azbyka.ru/biblia/?$slug">$label</a>';

/// Будний день: Апостол и Евангелие подряд, пометки «Лит.» нет.
final _liturgyOnlyReadings =
    '${_bibref('1Cor.14:6-19', '1Кор.14:6-19')} (зач. 155). '
    '${_bibref('Mt.20:17-28', 'Мф.20:17–28')} (зач. 81).';

/// Праздник: сперва утреня, затем «Лит.». Евангелие утрени идёт ПЕРВЫМ и без
/// отсечки по «Лит.» перехватило бы выбор.
final _matinsAndLiturgyReadings =
    'Утр. – '
    '${_bibref('Jn.10:9-16', 'Ин.10:9–16')} (зач. 36). Лит. – '
    '${_bibref('Gal.1:11-19', 'Гал.1:11–19')} (зач. 200). '
    '${_bibref('Jn.10:1-9', 'Ин.10:1–9')} (зач. 35).';

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
]) async => (await datasource.fetch(date ?? _date, timeout: _timeout)).cards;

Future<DayDto> _fetchDay(
  AzbykaDayCardsRemoteDatasource datasource, [
  DateTime? date,
]) => datasource.fetch(date ?? _date, timeout: _timeout);

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
            adviceHtml: '<p>СОВЕТ</p>',
            basicsHtml: '<p>ОСНОВЫ</p>',
          ),
        ),
      );

      expect(cards.map((c) => c.type).toList(), [
        'quote',
        'advice',
        'basics',
        'reading',
      ]);
      expect(_cardOfType(cards, 'quote').body, 'ЦИТАТА');
      expect(_cardOfType(cards, 'advice').body, 'СОВЕТ');
      expect(_cardOfType(cards, 'basics').body, 'ОСНОВЫ');
      expect(_cardOfType(cards, 'reading').body, 'Мф.20:17–28');
    });

    test('id складывается из типа и запрошенной даты', () async {
      final cards = await _fetch(_datasourceServing(_page()));

      expect(cards.map((c) => c.id).toSet(), {
        'quote-2026-07-19',
        'advice-2026-07-19',
        'basics-2026-07-19',
        'reading-2026-07-19',
      });
    });

    test('блок «Притча дня» становится карточкой притчи', () async {
      final cards = await _fetch(
        _datasourceServing(
          _page(parableHtml: '<p>ПЕРВЫЙ АБЗАЦ</p><p>ВТОРОЙ АБЗАЦ</p>'),
        ),
      );

      final parable = _cardOfType(cards, 'parable');
      expect(parable.id, 'parable-2026-07-19');
      expect(parable.body, 'ПЕРВЫЙ АБЗАЦ\n\nВТОРОЙ АБЗАЦ');
      // Заголовок секции («Притча дня») — не контент.
      expect(parable.body, isNot(contains('Притча')));
    });

    test('подпись под притчей уходит в источник, а не в текст', () async {
      // Карточка сама печатает «— {source}» под телом: оставь подпись
      // абзацем — и автор окажется на экране дважды, по-разному.
      final cards = await _fetch(
        _datasourceServing(
          _page(
            parableHtml:
                '<p>ТЕКСТ ПРИТЧИ</p>'
                '<p style="text-align: right;">'
                '<a href="/otechnik/Dorofej/"><em>авва Дорофей</em></a>'
                '</p>',
          ),
        ),
      );

      final parable = _cardOfType(cards, 'parable');
      expect(parable.body, 'ТЕКСТ ПРИТЧИ');
      expect(parable.source, 'авва Дорофей');
    });

    test('из подписи вырезается «см. иллюстрацию»', () async {
      // Ссылка ведёт на страницу сайта — внутри приложения идти по ней некуда.
      final cards = await _fetch(
        _datasourceServing(
          _page(
            parableHtml:
                '<p>ТЕКСТ</p>'
                '<p style="text-align: right;">авва Дорофей '
                '(см.<a href="/shemy/x.shtml"> иллюстрацию к этой притче</a>)'
                '</p>',
          ),
        ),
      );

      expect(_cardOfType(cards, 'parable').source, 'авва Дорофей');
    });

    test('заголовок притчи по центру остаётся в тексте', () async {
      // Выключка по центру — собственное название притчи, а не подпись:
      // опираться на «последний абзац» вместо выключки было бы неверно.
      final cards = await _fetch(
        _datasourceServing(
          _page(
            parableHtml:
                '<p style="text-align: center;">ХИТРЫЙ АРХИТЕКТОР</p>'
                '<p>ТЕКСТ</p>',
          ),
        ),
      );

      final parable = _cardOfType(cards, 'parable');
      expect(parable.body, 'ХИТРЫЙ АРХИТЕКТОР\n\nТЕКСТ');
      expect(parable.source, 'Азбука веры');
    });

    test('имя дня собирается из седмицы, памяти и пометки поста', () async {
      // Азбука рвёт эти строки ссылками и распорками с неразрывными
      // пробелами, поэтому берём текст блока целиком и схлопываем пробелы.
      final day = await _fetchDay(
        _datasourceServing(
          _page(
            headerHtml: '''
              <div class="day__post-wp dayinfo_color">
                <div class="shadow">
                  <div class="lc">&nbsp;</div>
                  <a href="/days/x">Седмица 2</a>-я <a href="/y">Великого поста</a>
                  <div class="rc">&nbsp;</div>
                </div>
              </div>
              <div class="text day__text">
                <p>
                  <a href="/days/p-kalendar-postov-i-trapez">Постный день.</a>
                  <a href="/glas">Глас</a> 5-й
                </p>
                <ul><li><a href="/days/z">Прп. Льва́, епископа Ката́нского
                  <span class="secondary-content">(ок. 780)</span></a></li></ul>
              </div>
            ''',
          ),
        ),
      );

      expect(day.week, 'Седмица 2-я Великого поста');
      // Год жизни отброшен: в шапке важно, чей это день, а не когда он был.
      expect(day.title, 'Прп. Льва́, епископа Ката́нского');
      expect(day.isFast, isTrue);
    });

    test('«Поста нет» не считается постным днём', () async {
      // Обе пометки — ссылки, и различает их только href: у поста это
      // календарь постов, у его отсутствия — общая статья о постах.
      final day = await _fetchDay(
        _datasourceServing(
          _page(
            headerHtml: '''
              <div class="text day__text">
                <p><a href="https://azbyka.ru/posty-pravoslavnoj-cerkvi">Поста </a>нет.</p>
                <ul><li><a href="/days/z">Прп. Сисо́я Великого</a></li></ul>
              </div>
            ''',
          ),
        ),
      );

      expect(day.isFast, isFalse);
      expect(day.title, 'Прп. Сисо́я Великого');
      // Блока седмицы на странице нет вовсе — так Азбука верстает великие
      // праздники: на Пасху вместо седмицы стоит сам праздник. Память при
      // этом на месте, и день не остаётся безымянным.
      expect(day.week, isNull);
    });

    test('без шапки день остаётся безымянным, но не падает', () async {
      final day = await _fetchDay(_datasourceServing(_page()));

      expect(day.week, isNull);
      expect(day.title, isNull);
      expect(day.isFast, isFalse);
      expect(day.cards, isNotEmpty);
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
      final cards = await _fetch(
        _datasourceServing(_page(quoteAuthorHtml: '')),
      );

      expect(_cardOfType(cards, 'quote').source, 'Азбука веры');
    });

    test('у остальных карточек источник всегда «Азбука веры»', () async {
      final cards = await _fetch(_datasourceServing(_page()));

      for (final type in ['advice', 'basics', 'reading']) {
        expect(_cardOfType(cards, type).source, 'Азбука веры');
      }
    });
  });

  group('выбор чтения дня', () {
    test('будний день: берётся Евангелие, а не Апостол', () async {
      final cards = await _fetch(_datasourceServing(_page()));

      final reading = _cardOfType(cards, 'reading');
      expect(reading.reference, 'Mt.20:17-28');
      expect(reading.body, 'Мф.20:17–28');
    });

    test('с пометкой «Лит.» утреня пропускается', () async {
      // Евангелие утрени (Ин.10:9–16) стоит первым и без отсечки победило бы.
      final cards = await _fetch(
        _datasourceServing(_page(readingsHtml: _matinsAndLiturgyReadings)),
      );

      expect(_cardOfType(cards, 'reading').reference, 'Jn.10:1-9');
    });

    test('пометка «Лит.» ссылкой тоже отсекает утреню', () async {
      // Живая вёрстка Азбуки: `<a href="/liturgiya">Лит</a>.` — точка лежит
      // в соседнем узле. Поиск «Лит.» по тексту одного узла промахивался,
      // и в ридер уходило Евангелие утрени.
      final cards = await _fetch(
        _datasourceServing(
          _page(
            readingsHtml:
                'Утр. – '
                '${_bibref('Jn.10:9-16', 'Ин.10:9–16')} (зач. 36). '
                '<a href="https://azbyka.ru/liturgiya">Лит</a>. &ndash; '
                '${_bibref('Gal.1:11-19', 'Гал.1:11–19')} (зач. 200). '
                '${_bibref('Jn.10:1-9', 'Ин.10:1–9')} (зач. 35).',
          ),
        ),
      );

      expect(_cardOfType(cards, 'reading').reference, 'Jn.10:1-9');
    });

    test('чтения без Евангелия — карточки чтения нет', () async {
      final cards = await _fetch(
        _datasourceServing(
          _page(readingsHtml: _bibref('1Cor.14:6-19', '1Кор.14:6-19')),
        ),
      );

      expect(cards.map((c) => c.type), isNot(contains('reading')));
    });

    test('типографское тире в ссылке нормализуется в дефис', () async {
      // Иначе ридер уйдёт за отрывком по ссылке, которой Азбука не знает.
      final cards = await _fetch(
        _datasourceServing(
          _page(readingsHtml: _bibref('Lk.7:36–50', 'Лк.7:36–50')),
        ),
      );

      expect(_cardOfType(cards, 'reading').reference, 'Lk.7:36-50');
    });

    test('только у карточки чтения есть reference', () async {
      final cards = await _fetch(_datasourceServing(_page()));

      for (final card in cards.where((c) => c.type != 'reading')) {
        expect(
          card.reference,
          isNull,
          reason: 'у ${card.type} лишний reference',
        );
      }
    });
  });

  // FR-005: Азбука публикует не все разделы каждый день, и раньше пропажа
  // любого из пяти уводила приложение в офлайн-экран при живом интернете.
  group('неполный день', () {
    test('пропавшая секция выпадает, остальные на месте', () async {
      final cards = await _fetch(
        _datasourceServing(_page(adviceHtml: '', basicsHtml: '')),
      );

      expect(cards.map((c) => c.type), ['quote', 'reading']);
    });

    test('порядок уцелевших карточек не сбивается', () async {
      final cards = await _fetch(_datasourceServing(_page(basicsHtml: '')));

      expect(cards.map((c) => c.type), ['quote', 'advice', 'reading']);
    });

    test('день из одной цитаты — валидный день', () async {
      final cards = await _fetch(
        _datasourceServing(
          _page(adviceHtml: '', basicsHtml: '', readingsHtml: ''),
        ),
      );

      expect(cards.map((c) => c.type), ['quote']);
      expect(cards.single.body, 'QUOTE');
    });

    test('пустая секция считается пропавшей, а не ломает день', () async {
      final cards = await _fetch(
        _datasourceServing(_page(readingsHtml: '   ')),
      );

      expect(cards.map((c) => c.type), ['quote', 'advice', 'basics']);
    });

    test('цитата без абзаца с автором не роняет разбор', () async {
      // paragraphs[1] без проверки длины падал бы RangeError, а не пропуском.
      final cards = await _fetch(
        _datasourceServing('''
<html><body>
  <div class="widget quote-of-day"><div class="box"><p>ОДИН АБЗАЦ</p></div></div>
</body></html>
'''),
      );

      expect(cards.single.body, 'ОДИН АБЗАЦ');
      expect(cards.single.source, 'Азбука веры');
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
      // Этот вариант уводил приложение в вечный офлайн-экран при живом интернете.
      final cards = await _fetch(
        _datasourceServing(_page(basicsHtml: 'ПЕРВЫЙ<br>ВТОРОЙ<br>ТРЕТИЙ')),
      );

      expect(_cardOfType(cards, 'basics').body, 'ПЕРВЫЙ\n\nВТОРОЙ\n\nТРЕТИЙ');
    });

    test('<br> внутри <p> тоже даёт перенос, а не слипшийся текст', () async {
      final cards = await _fetch(
        _datasourceServing(_page(adviceHtml: '<p>СТРОКА<br>ЕЩЁ</p>')),
      );

      expect(_cardOfType(cards, 'advice').body, 'СТРОКА\nЕЩЁ');
    });

    test(
      'ответ списком <ul><li> попадает в карточку вместе с вопросом',
      () async {
        // Так Азбука сверстала «совет дня» 31 июля: вопрос абзацем, весь ответ
        // списком. Сбор одних <p> возвращал непустой результат, поэтому карточка
        // показывала вопрос БЕЗ ответа и выглядела рабочей.
        final cards = await _fetch(
          _datasourceServing(
            _page(
              adviceHtml:
                  '<p><strong>МОЖНО ЛИ?</strong></p>'
                  '<ul><li>МОЖНО РАДИ ОДНОГО</li>'
                  '<li>МОЖНО РАДИ ДРУГОГО</li>'
                  '<li>А ВОТ ЭТО ЗАПРЕЩЕНО</li></ul>',
            ),
          ),
        );

        final advice = _cardOfType(cards, 'advice').body;
        expect(advice, contains('МОЖНО ЛИ?'));
        expect(advice, contains('МОЖНО РАДИ ОДНОГО'));
        expect(advice, contains('МОЖНО РАДИ ДРУГОГО'));
        expect(advice, contains('А ВОТ ЭТО ЗАПРЕЩЕНО'));
        expect(advice.split('\n\n'), hasLength(4));
      },
    );

    test('кривое вложенное <p><p> не задваивает текст', () async {
      // Именно так приходит разметка Азбуки: <p><p><strong>…</strong></p>.
      final cards = await _fetch(
        _datasourceServing(
          _page(adviceHtml: '<p><p><strong>ОДИН РАЗ</strong></p></p>'),
        ),
      );

      expect(_cardOfType(cards, 'advice').body, 'ОДИН РАЗ');
    });

    test('заголовок секции не утекает в текст карточки', () async {
      // Без <p> контентом становится весь контейнер целиком, вместе с <h2>,
      // если его не выкинуть.
      final cards = await _fetch(
        _datasourceServing(_page(adviceHtml: 'ГОЛЫЙ ТЕКСТ')),
      );

      final advice = _cardOfType(cards, 'advice');
      expect(advice.body, 'ГОЛЫЙ ТЕКСТ');
      expect(advice.body, isNot(contains('Практический совет')));
    });
  });

  group('реальные страницы azbyka', () {
    // Дымовой тест на живой вёрстке: содержимое не проверяется (оно
    // принадлежит Азбуке и меняется каждый день), важны только селекторы.
    // 19 июля — секции через <p>, 20 июля — притча голым текстом с <br>:
    // два дня закрывают обе формы разметки.
    for (final date in ['2026-07-19', '2026-07-20']) {
      test('$date разбирается в пять непустых карточек', () async {
        final cards = await _fetch(
          _datasourceServing(
            _loadFixture(date),
            expectUrl: 'https://azbyka.ru/days/$date',
          ),
          DateTime.parse(date),
        );

        expect(cards.map((c) => c.type).toList(), [
          'quote',
          'advice',
          'basics',
          'reading',
          'parable',
        ]);
        for (final card in cards) {
          expect(card.id, '${card.type}-$date');
          expect(card.body.trim(), isNotEmpty, reason: 'пустая ${card.type}');
          expect(card.source.trim(), isNotEmpty);
        }
      });
    }

    test('19 июля разбирается имя дня', () async {
      final day = await _fetchDay(
        _datasourceServing(
          _loadFixture('2026-07-19'),
          expectUrl: 'https://azbyka.ru/days/2026-07-19',
        ),
        DateTime(2026, 7, 19),
      );

      expect(day.week, 'Неделя 7-я по Пятидесятнице');
      expect(day.title, 'Прп. Сисо́я Великого');
      expect(day.isFast, isFalse);
    });

    test('20 июля чтение — евангельский отрывок со ссылкой', () async {
      final cards = await _fetch(
        _datasourceServing(
          _loadFixture('2026-07-20'),
          expectUrl: 'https://azbyka.ru/days/2026-07-20',
        ),
        DateTime(2026, 7, 20),
      );

      final reading = _cardOfType(cards, 'reading');
      expect(reading.reference, matches(RegExp(r'^(Mt|Mk|Lk|Jn)\.\d+:\d+')));
      expect(reading.body, isNotEmpty);
    });
  });

  group('ошибки', () {
    test('не-200 → RemoteFetchException с kind server', () async {
      await expectLater(
        () => _fetch(_datasourceServing(_page(), statusCode: 500)),
        throwsA(
          isA<RemoteFetchException>().having(
            (e) => e.kind,
            'kind',
            FailureKind.server,
          ),
        ),
      );
    });

    test('ни одной секции на странице → unknown: это сломанная вёрстка,'
        ' а не неполный день', () async {
      await expectLater(
        () => _fetch(_datasourceServing('<html><body></body></html>')),
        throwsA(
          isA<RemoteFetchException>().having(
            (e) => e.kind,
            'kind',
            FailureKind.unknown,
          ),
        ),
      );
    });

    test('ответ не пришёл за таймаут → kind network', () async {
      final client = MockClient((request) async {
        await Future<void>.delayed(const Duration(seconds: 1));
        return http.Response('', 200);
      });

      await expectLater(
        () => AzbykaDayCardsRemoteDatasource(
          client: client,
        ).fetch(_date, timeout: const Duration(milliseconds: 10)),
        throwsA(
          isA<RemoteFetchException>().having(
            (e) => e.kind,
            'kind',
            FailureKind.network,
          ),
        ),
      );
    });
  });
}
