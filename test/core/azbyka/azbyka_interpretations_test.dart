import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:lampada/core/azbyka/azbyka_interpretations.dart';

/// Заголовок блока со ссылкой на стих — так его верстает Азбука.
String _h5(String book, int chapter, int verse, String abbr, String text) =>
    '<p class="h5"><span class="bibText1">'
    '<a href="https://azbyka.ru/biblia/?$book.$chapter:$verse">'
    '$abbr.$chapter:$verse</a>.</span> '
    '<span class="quote synodal">$text</span></p>';

/// Подзаголовок: следующий фрагмент того же стиха, без ссылки.
String _sub(String text) =>
    '<p class="h5"> <span class="quote synodal">$text</span></p>';

String _txt(String text) => '<p class="txt">$text</p>';

Map<int, AzbykaInterpretation> _parse(
  List<String> body, {
  String book = 'Rom',
  int chapter = 1,
  String abbreviation = 'Рим',
}) => AzbykaInterpretations.byVerse(
  html_parser.parse('<html><body>${body.join()}</body></html>'),
  book: book,
  chapter: chapter,
  abbreviation: abbreviation,
);

void main() {
  group('толкование по стихам', () {
    test('подпись отрывка строится по переданному сокращению книги', () {
      final result = _parse(
        [
          _h5('Gen', 1, 1, 'Быт', 'В начале'),
          _h5('Gen', 1, 2, 'Быт', 'Земля же была'),
          _txt('ОБЩИЙ КОММЕНТАРИЙ'),
        ],
        book: 'Gen',
        abbreviation: 'Быт',
      );

      expect(result.keys, [2]);
      expect(result[2]!.range, 'Быт.1:1–2');
      expect(result[2]!.text, 'ОБЩИЙ КОММЕНТАРИЙ');
    });

    test('комментарий после подзаголовка остаётся у того же стиха', () {
      // Феофилакт на Послания и Лопухин делят стих на фрагменты: «Павел,»,
      // «раб», «Иисуса Христа». Без подзаголовков терялось всё, кроме
      // комментария к первому фрагменту.
      final result = _parse([
        _h5('Rom', 1, 1, 'Рим', 'Павел,'),
        _txt('О ПАВЛЕ'),
        _sub('раб'),
        _txt('О РАБСТВЕ'),
        _h5('Rom', 1, 2, 'Рим', 'которое Бог прежде обещал'),
        _txt('О ВТОРОМ СТИХЕ'),
      ]);

      expect(result[1]!.text, '«Павел»\n\nО ПАВЛЕ\n\n«раб»\n\nО РАБСТВЕ');
      expect(result[1]!.range, 'Рим.1:1');
      // Целый стих без фрагментов подписывать нечем и незачем.
      expect(result[2]!.text, 'О ВТОРОМ СТИХЕ');
    });

    test('вступление до первого стиха ни к чему не привязывается', () {
      final result = _parse([
        _sub('Глава 1. Надписание послания'),
        _txt('ВСТУПЛЕНИЕ'),
        _h5('Rom', 1, 1, 'Рим', 'Павел,'),
        _txt('О ПАВЛЕ'),
      ]);

      expect(result.keys, [1]);
      expect(result[1]!.text, 'О ПАВЛЕ');
    });

    test('блок на стих другой главы не дописывается к предыдущему', () {
      final result = _parse([
        _h5('Rom', 1, 32, 'Рим', 'Они знают праведный суд'),
        _txt('О 32 СТИХЕ'),
        _h5('Rom', 2, 1, 'Рим', 'Итак, неизвинителен'),
        _txt('УЖЕ ВТОРАЯ ГЛАВА'),
      ]);

      expect(result.keys, [32]);
      expect(result[32]!.text, 'О 32 СТИХЕ');
    });
  });

  group('выбор толкователя', () {
    String page(List<(String, String)> links) =>
        '<ul class="interprets">'
        '${links.map((l) => '<li><a href="${l.$1}">${l.$2}</a></li>').join()}'
        '</ul>';

    test('берёт первого толкователя по приоритету, а не по порядку', () {
      final link = AzbykaInterpretations.interpreterLink(
        html_parser.parse(
          page([
            ('/otechnik/Lopuhin/tolkovaja_biblija_63/1', 'Лопухин'),
            ('/otechnik/Feofilakt_Bolgarskij/rim/1', 'Феофилакт'),
          ]),
        ),
        const ['Feofilakt_Bolgarskij', 'Lopuhin'],
      );

      expect(
        link?.href,
        'https://azbyka.ru/otechnik/Feofilakt_Bolgarskij/rim/1',
      );
      expect(link?.author, 'Феофилакт');
    });

    test('без первого по приоритету берёт следующего', () {
      final link = AzbykaInterpretations.interpreterLink(
        html_parser.parse(
          page([('/otechnik/Lopuhin/tolkovaja_biblija_01/1', 'Лопухин')]),
        ),
        const ['Feofilakt_Bolgarskij', 'Lopuhin'],
      );

      expect(link?.author, 'Лопухин');
    });

    test('нет ни одного из толкователей — null', () {
      final link = AzbykaInterpretations.interpreterLink(
        html_parser.parse(page([('/otechnik/Efrem_Sirin/x/1', 'Ефрем')])),
        const ['Feofilakt_Bolgarskij'],
      );

      expect(link, isNull);
    });
  });
}
