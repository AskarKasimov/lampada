import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lampada/features/bible/data/datasources/bible_remote_datasource.dart';

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
}
