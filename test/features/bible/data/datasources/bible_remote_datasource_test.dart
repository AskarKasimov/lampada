import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lampada/features/bible/data/datasources/bible_remote_datasource.dart';

String _chapterPage({String interprets = ''}) =>
    '<div class="verse lang-r" data-verse="Gen.1:1">В начале</div>'
    '<div class="verse lang-r" data-verse="Gen.1:2">Земля же</div>'
    '<ul class="interprets">$interprets</ul>';

const _lopuhin =
    '<li><a href="/otechnik/Lopuhin/tolkovaja_biblija_01/1">'
    'Толковая Библия А.П. Лопухина</a></li>';

const _interpretationPage =
    '<p class="h5"><span class="bibText1">'
    '<a href="https://azbyka.ru/biblia/?Gen.1:2">Быт.1:2</a>.</span> '
    '<span class="quote synodal">Земля же</span></p>'
    '<p class="txt">О ЗЕМЛЕ</p>';

/// Первый запрос — глава, второй — страница толкования.
AzbykaBibleRemoteDatasource _serving({
  required String chapter,
  int interpretationStatus = 200,
}) => AzbykaBibleRemoteDatasource(
  client: MockClient((request) async {
    final isInterpretation = request.url.path.contains('otechnik');
    return http.Response.bytes(
      utf8.encode(isInterpretation ? _interpretationPage : chapter),
      isInterpretation ? interpretationStatus : 200,
    );
  }),
);

void main() {
  test('читает только синодальные стихи выбранной главы', () async {
    final source = AzbykaBibleRemoteDatasource(
      client: MockClient((request) async {
        expect(request.url.toString(), 'https://azbyka.ru/biblia/?Jn.3&r');
        return http.Response.bytes(
          utf8.encode('''
        <div class="verse lang-r" data-verse="Jn.3:1">Первый стих<span class="icon-check checkbox"></span></div>
        <div class="verse lang-c" data-verse="Jn.3:1">Другой перевод</div>
        <div class="verse lang-r" data-verse="Jn.3:2">Второй <span class="zachala">зачало</span>стих</div>
        <div class="verse lang-r" data-verse="Jn.4:1">Чужая глава</div>
      '''),
          200,
        );
      }),
    );

    final chapter = await source.fetchChapter('Jn', 3);
    expect(chapter.verses.map((verse) => verse.text), [
      'Первый стих',
      'Второй стих',
    ]);
    expect(chapter.verses.map((verse) => verse.number), [1, 2]);
  });

  test(
    'убирает пустую пометку зачала и скрытую подсказку, сохраняя текст в скобках',
    () async {
      final source = AzbykaBibleRemoteDatasource(
        client: MockClient(
          (_) async => http.Response.bytes(
            utf8.encode('''
        <div class="verse lang-r" data-verse="Gen.1:1">[<span class="zachala">Зач. 1.</span>] В начале <abbr><span class="info" aria-hidden="true">Пояснение сайта</span>[сотворил Бог]</abbr> небо и землю.<span class="checkbox"></span></div>
      '''),
            200,
          ),
        ),
      );

      final chapter = await source.fetchChapter('Gen', 1);
      expect(
        chapter.verses.single.text,
        'В начале [сотворил Бог] небо и землю.',
      );
    },
  );

  group('толкование', () {
    test('привязывается к стиху и подписывается сокращением книги', () async {
      final chapter = await _serving(
        chapter: _chapterPage(interprets: _lopuhin),
      ).fetchChapter('Gen', 1);

      expect(chapter.verses[0].interpretation, isNull);
      expect(chapter.verses[1].interpretation, 'О ЗЕМЛЕ');
      expect(chapter.verses[1].interpretationRange, 'Быт.1:2');
      expect(chapter.interpretationAuthor, 'Толковая Библия А.П. Лопухина');
      expect(chapter.interpretationsChecked, isTrue);
    });

    test(
      'сбой толкования не скрывает главу и оставляет её на перепроверку',
      () async {
        final chapter = await _serving(
          chapter: _chapterPage(interprets: _lopuhin),
          interpretationStatus: 500,
        ).fetchChapter('Gen', 1);

        expect(chapter.verses, hasLength(2));
        expect(chapter.verses.every((v) => v.interpretation == null), isTrue);
        expect(chapter.interpretationAuthor, isNull);
        expect(chapter.interpretationsChecked, isFalse);
      },
    );

    test('у главы нет толкователя — это окончательный ответ', () async {
      final chapter = await _serving(
        chapter: _chapterPage(),
      ).fetchChapter('Gen', 1);

      expect(chapter.verses.every((v) => v.interpretation == null), isTrue);
      expect(chapter.interpretationsChecked, isTrue);
    });
  });
}
