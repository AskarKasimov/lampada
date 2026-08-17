import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lampada/core/network/remote_fetch_exception.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/reading/data/datasources/reading_remote_datasource.dart';

/// Разметка стиха у Азбуки: номер главы и стиха в data-verse, язык — в классе.
/// Русский синодальный это `lang-r`; церковнославянский приходит как `lang-cs`
/// и в ридер попадать не должен.
String _verse(
  int chapter,
  int number,
  String text, {
  String lang = 'r',
  bool zachalo = false,
}) =>
    '<div data-lang="$lang" data-chapter="$chapter" data-line="$number" '
    'data-verse="Jn.$chapter:$number" '
    'class="verse lang-$lang line-$number col-1">'
    // Скобки вокруг зачала Азбука кладёт ОТДЕЛЬНЫМИ текстовыми узлами,
    // снаружи спана — удаление спана оставляло на экране «[]».
    '${zachalo ? '[<span class="zachala"><a href="/zachala">Зач. 36.</a></span>] ' : ''}'
    '<span class="christ-speech">$text</span>'
    '<span class="icon-check checkbox"></span></div>';

String _passagePage({
  required String versesHtml,
  String interpretsHtml =
      '<ul class="interprets">'
      '<li><a href="/otechnik/Feofilakt_Bolgarskij/tolkovanie-na-evangelie-ot-ioanna/10">'
      'Феофилакт Болгарский, блж.</a></li></ul>',
}) =>
    '<html><body><div class="tbl-content">$versesHtml</div>'
    '$interpretsHtml</body></html>';

/// Ссылка на стих в блоке толкования — так её верстает Азбука.
String _h5(int verse, String text) =>
    '<p class="h5"><span class="bibText1">'
    '<a href="https://azbyka.ru/biblia/?Jn.10:$verse">Ин.10:$verse</a></span>.'
    '</span> <span class="quote synodal">$text</span></p>';

String _txt(String text) => '<p class="txt">$text</p>';

/// Страница толкования. Устроена пробегами: сначала ссылки на стихи
/// (`p.h5`), затем комментарий на всю группу (`p.txt`).
String _interpretationPage(String body) =>
    '<html><body><a id="10"></a><div>$body</div></body></html>';

/// Каждому стиху свой комментарий.
final _perVerseChapter = [
  _h5(1, 'Истинно говорю вам'),
  _txt('КОММЕНТАРИЙ ПЕРВЫЙ'),
  _h5(2, 'А входящий дверью'),
  _txt('КОММЕНТАРИЙ ВТОРОЙ'),
  _h5(3, 'Ему придверник отворяет'),
  _txt('КОММЕНТАРИЙ ТРЕТИЙ'),
].join();

/// Один комментарий на группу стихов 1–3 — так у Феофилакта размечена,
/// например, вся притча в Мф.20:1–7.
final _groupedChapter = [
  _h5(1, 'Истинно говорю вам'),
  _h5(2, 'А входящий дверью'),
  _h5(3, 'Ему придверник отворяет'),
  _txt('КОММЕНТАРИЙ НА ПРИТЧУ'),
  _txt('ВТОРОЙ АБЗАЦ КОММЕНТАРИЯ'),
  _h5(4, 'И когда выведет'),
  _txt('КОММЕНТАРИЙ ЧЕТВЁРТЫЙ'),
].join();

/// Группа из одного стиха с комментарием в два абзаца — изолирует склейку
/// `p.txt` от вопроса «какому стиху из группы достаётся текст».
final _singleVerseTwoParagraphs = [
  _h5(1, 'Истинно говорю вам'),
  _txt('АБЗАЦ ПЕРВЫЙ'),
  _txt('АБЗАЦ ВТОРОЙ'),
].join();

/// Датасорс с подставными ответами: первый запрос — отрывок, второй —
/// толкование. Заодно собираем URL, чтобы проверить параметр языка.
({AzbykaReadingRemoteDatasource datasource, List<String> urls}) _serving({
  required String passage,
  String? interpretation,
  int interpretationStatus = 200,
}) {
  final urls = <String>[];
  final client = MockClient((request) async {
    urls.add(request.url.toString());
    if (request.url.path.contains('otechnik')) {
      return http.Response(
        interpretation ?? '',
        interpretationStatus,
        headers: {'content-type': 'text/html; charset=utf-8'},
      );
    }
    return http.Response(
      passage,
      200,
      headers: {'content-type': 'text/html; charset=utf-8'},
    );
  });
  return (
    datasource: AzbykaReadingRemoteDatasource(client: client),
    urls: urls,
  );
}

void main() {
  const timeout = Duration(seconds: 5);

  group('PassageRef', () {
    test('одна глава: Jn.10:1-9', () {
      final ref = PassageRef.tryParse('Jn.10:1-9')!;
      expect(ref.book, 'Jn');
      expect((ref.fromChapter, ref.fromVerse), (10, 1));
      expect((ref.toChapter, ref.toVerse), (10, 9));
    });

    test('межглавный отрывок: Mt.16:20-17:9', () {
      // Без разбора второй главы хвост отрывка просто пропал бы.
      final ref = PassageRef.tryParse('Mt.16:20-17:9')!;
      expect((ref.fromChapter, ref.fromVerse), (16, 20));
      expect((ref.toChapter, ref.toVerse), (17, 9));
    });

    test('один стих без диапазона', () {
      final ref = PassageRef.tryParse('Lk.7:36')!;
      expect((ref.toChapter, ref.toVerse), (7, 36));
    });

    test('мусор не разбирается', () {
      expect(PassageRef.tryParse('не ссылка'), isNull);
    });

    test('contains уважает границы глав', () {
      final ref = PassageRef.tryParse('Mt.16:20-17:9')!;
      expect(ref.contains(16, 19), isFalse);
      expect(ref.contains(16, 20), isTrue);
      expect(ref.contains(17, 9), isTrue);
      expect(ref.contains(17, 10), isFalse);
    });
  });

  group('загрузка отрывка', () {
    test('запрашивает русский перевод параметром &r', () async {
      // Без &r Азбука на части отрывков отдаёт церковнославянский —
      // новоначальный получил бы нечитаемый текст.
      final s = _serving(
        passage: _passagePage(versesHtml: _verse(10, 1, 'СТИХ')),
        interpretation: _interpretationPage(_perVerseChapter),
      );

      await s.datasource.fetch('Jn.10:1-1', timeout: timeout);

      expect(s.urls.first, 'https://azbyka.ru/biblia/?Jn.10:1-1&r');
    });

    test('берёт только стихи запрошенного диапазона', () async {
      final s = _serving(
        passage: _passagePage(
          versesHtml: [
            for (var i = 1; i <= 5; i++) _verse(10, i, 'СТИХ $i'),
          ].join(),
        ),
        interpretation: _interpretationPage(_perVerseChapter),
      );

      final dto = await s.datasource.fetch('Jn.10:2-4', timeout: timeout);

      expect(dto.verses.map((v) => v.number), [2, 3, 4]);
      expect(dto.verses.first.text, 'СТИХ 2');
    });

    test('церковнославянские стихи отбрасываются', () async {
      final s = _serving(
        passage: _passagePage(
          versesHtml:
              _verse(10, 1, 'СЛАВЯНСКИЙ', lang: 'cs') +
              _verse(10, 1, 'РУССКИЙ'),
        ),
        interpretation: _interpretationPage(_perVerseChapter),
      );

      final dto = await s.datasource.fetch('Jn.10:1-1', timeout: timeout);

      expect(dto.verses.single.text, 'РУССКИЙ');
    });

    test('богослужебная пометка «Зач.» в текст стиха не попадает', () async {
      final s = _serving(
        passage: _passagePage(
          versesHtml: _verse(10, 1, 'Я есмь дверь.', zachalo: true),
        ),
        interpretation: _interpretationPage(_perVerseChapter),
      );

      final dto = await s.datasource.fetch('Jn.10:1-1', timeout: timeout);

      expect(dto.verses.single.text, 'Я есмь дверь.');
      expect(dto.verses.single.text, isNot(contains('Зач')));
    });

    test('человекочитаемая подпись отрывка', () async {
      final s = _serving(
        passage: _passagePage(versesHtml: _verse(10, 1, 'СТИХ')),
        interpretation: _interpretationPage(_perVerseChapter),
      );

      final dto = await s.datasource.fetch('Jn.10:1-9', timeout: timeout);

      expect(dto.label, 'Ин.10:1–9');
    });

    test('на странице нет стихов → unknown, ретраить нечего', () async {
      final s = _serving(passage: _passagePage(versesHtml: ''));

      await expectLater(
        () => s.datasource.fetch('Jn.10:1-9', timeout: timeout),
        throwsA(
          isA<RemoteFetchException>().having(
            (e) => e.kind,
            'kind',
            FailureKind.unknown,
          ),
        ),
      );
    });
  });

  group('толкование по стихам', () {
    test('у каждого стиха своё толкование, когда так размечено', () async {
      final s = _serving(
        passage: _passagePage(
          versesHtml: [
            for (var i = 1; i <= 3; i++) _verse(10, i, 'СТИХ $i'),
          ].join(),
        ),
        interpretation: _interpretationPage(_perVerseChapter),
      );

      final dto = await s.datasource.fetch('Jn.10:1-3', timeout: timeout);

      expect(dto.verses[0].interpretation, 'КОММЕНТАРИЙ ПЕРВЫЙ');
      expect(dto.verses[1].interpretation, 'КОММЕНТАРИЙ ВТОРОЙ');
      expect(dto.verses[2].interpretation, 'КОММЕНТАРИЙ ТРЕТИЙ');
    });

    test('подпись отрывка у одиночного стиха — сам стих', () async {
      final s = _serving(
        passage: _passagePage(versesHtml: _verse(10, 2, 'СТИХ')),
        interpretation: _interpretationPage(_perVerseChapter),
      );

      final dto = await s.datasource.fetch('Jn.10:2-2', timeout: timeout);

      expect(dto.verses.single.interpretationRange, 'Ин.10:2');
    });

    test(
      'один блок на группу стихов достаётся только последнему стиху группы',
      () async {
        // У Феофилакта на Мф.20 один комментарий покрывает стихи 1–7.
        // Нарезка «по стиху» отдала бы юзеру сам стих вместо толкования —
        // но и кнопка НА КАЖДОМ стихе группы была бы неправдой другого рода:
        // звала бы за мыслью раньше, чем дочитан стих, которым она
        // завершается. Кнопка — только на последнем стихе группы (3-м).
        final s = _serving(
          passage: _passagePage(
            versesHtml: [
              for (var i = 1; i <= 4; i++) _verse(10, i, 'СТИХ $i'),
            ].join(),
          ),
          interpretation: _interpretationPage(_groupedChapter),
        );

        final dto = await s.datasource.fetch('Jn.10:1-4', timeout: timeout);

        expect(dto.verses[0].interpretation, isNull);
        expect(dto.verses[1].interpretation, isNull);
        expect(dto.verses[2].interpretation, contains('КОММЕНТАРИЙ НА ПРИТЧУ'));
        expect(dto.verses[2].interpretationRange, 'Ин.10:1–3');
        // Четвёртый стих — уже своя группа из одного стиха, и это его
        // единственный стих, так что толкование остаётся при нём.
        expect(dto.verses[3].interpretation, 'КОММЕНТАРИЙ ЧЕТВЁРТЫЙ');
        expect(dto.verses[3].interpretationRange, 'Ин.10:4');
      },
    );

    test('абзацы одного блока склеиваются, а не теряются', () async {
      final s = _serving(
        passage: _passagePage(versesHtml: _verse(10, 1, 'СТИХ')),
        interpretation: _interpretationPage(_singleVerseTwoParagraphs),
      );

      final dto = await s.datasource.fetch('Jn.10:1-1', timeout: timeout);

      expect(
        dto.verses.single.interpretation,
        'АБЗАЦ ПЕРВЫЙ\n\nАБЗАЦ ВТОРОЙ',
      );
    });

    test('стих без толкования остаётся без него', () async {
      // Группа без завершающего p.txt толкования не получает — обещать
      // кнопкой пустоту нельзя.
      final s = _serving(
        passage: _passagePage(versesHtml: _verse(10, 9, 'СТИХ 9')),
        interpretation: _interpretationPage(_perVerseChapter),
      );

      final dto = await s.datasource.fetch('Jn.10:9-9', timeout: timeout);

      expect(dto.verses.single.interpretation, isNull);
      expect(dto.verses.single.interpretationRange, isNull);
    });

    test('автор берётся из списка толкователей на странице', () async {
      final s = _serving(
        passage: _passagePage(versesHtml: _verse(10, 1, 'СТИХ')),
        interpretation: _interpretationPage(_perVerseChapter),
      );

      final dto = await s.datasource.fetch('Jn.10:1-1', timeout: timeout);

      expect(dto.interpretationAuthor, 'Феофилакт Болгарский, блж.');
    });

    test('нет Феофилакта в списке — чтение всё равно отдаётся', () async {
      final s = _serving(
        passage: _passagePage(
          versesHtml: _verse(10, 1, 'СТИХ'),
          interpretsHtml:
              '<ul class="interprets">'
              '<li><a href="/otechnik/Lopuhin/x/10">Лопухин</a></li></ul>',
        ),
      );

      final dto = await s.datasource.fetch('Jn.10:1-1', timeout: timeout);

      expect(dto.verses, hasLength(1));
      expect(dto.verses.single.interpretation, isNull);
    });

    test('страница толкования упала — чтение всё равно отдаётся', () async {
      // Толкование приятно, но само чтение состоятельно и без него.
      final s = _serving(
        passage: _passagePage(versesHtml: _verse(10, 1, 'СТИХ')),
        interpretationStatus: 500,
      );

      final dto = await s.datasource.fetch('Jn.10:1-1', timeout: timeout);

      expect(dto.verses, hasLength(1));
      expect(dto.verses.single.interpretation, isNull);
    });
  });
}
