import 'dart:async';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../../../../core/log/net_log.dart';
import '../../../../core/network/remote_fetch_exception.dart';
import '../../../../core/result/result.dart';
import '../dto/day_story_dto.dart';

abstract interface class DayStoryRemoteDatasource {
  Future<DayStoryDto> fetch(String url, {required Duration timeout});
}

/// Скрейпит страницу праздника/святого — ту, что находится по `storyUrl`
/// со страницы дня (`day_cards_remote_datasource.dart`).
///
/// У Азбуки два шаблона такой страницы: `.holiday-description .brif` —
/// у праздников, `.saint-description .brif` — у отдельных святых. Перед
/// `.brif` часто стоит `.short-description` — короткая версия того же
/// текста, но она лежит СНАРУЖИ `.brif` и в выборку не попадает: полная
/// версия внутри рассказывает то же самое подробнее.
///
/// Иногда `storyUrl` ведёт на совсем другой шаблон (у больших праздников —
/// на отдельную статью без `.brif` вовсе, например «Пасха в …году»). Это не
/// повод падать: сбоем считается только страница, где искомого блока нет.
class AzbykaDayStoryRemoteDatasource implements DayStoryRemoteDatasource {
  AzbykaDayStoryRemoteDatasource({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const _selector =
      '.holiday-description .brif, .saint-description .brif';

  @override
  Future<DayStoryDto> fetch(String url, {required Duration timeout}) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host != 'azbyka.ru') {
      throw RemoteFetchException(
        FailureKind.unknown,
        FormatException('недопустимая ссылка рассказа: $url'),
      );
    }

    final elapsed = Stopwatch()..start();
    netLog('GET $uri (отведено ${timeout.inMilliseconds}мс)');
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException catch (e) {
      throw RemoteFetchException(FailureKind.network, e);
    } on SocketException catch (e) {
      throw RemoteFetchException(FailureKind.network, e);
    } on http.ClientException catch (e) {
      throw RemoteFetchException(FailureKind.network, e);
    }
    if (response.statusCode != 200) {
      throw RemoteFetchException(
        FailureKind.server,
        HttpException('azbyka.ru вернул ${response.statusCode}', uri: uri),
      );
    }

    final doc = html_parser.parse(response.body);
    final container = doc.querySelector(_selector);
    if (container == null) {
      netLog('нет .brif на странице рассказа → unknown');
      throw RemoteFetchException(
        FailureKind.unknown,
        const FormatException('на странице нет описания праздника/святого'),
      );
    }

    final paragraphs = _paragraphsFrom(container);
    if (paragraphs.isEmpty) {
      netLog('описание праздника/святого пустое → unknown');
      throw RemoteFetchException(
        FailureKind.unknown,
        const FormatException('описание праздника/святого пустое'),
      );
    }
    netLog('${paragraphs.length} абзацев за ${elapsed.elapsedMilliseconds}мс');
    return DayStoryDto(paragraphs: paragraphs);
  }

  /// Абзацы рассказа. Заголовок секции (`Житие …`, `Праздник … празднуется …`)
  /// вырезаем как служебный — заголовок дня уже показан экраном, который
  /// сюда привёл. Ссылки на сноски (`[1]`, `[2]`…) — тоже: без работающего
  /// перехода к примечанию это просто мусор посреди фразы.
  static List<String> _paragraphsFrom(Element container) {
    container.querySelectorAll('h2, h3, h4').forEach((e) => e.remove());
    container.querySelectorAll('sup').forEach((e) => e.remove());

    final parts = <String>[];
    for (final el in container.querySelectorAll('p, li')) {
      if (el.querySelector('p, li, ul, ol') != null) continue;
      final text = _textWithBreaks(el);
      if (text.isNotEmpty) parts.add(text);
    }
    return parts;
  }

  /// <br> не даёт пробела в Element.text — заменяем на \n.
  static String _textWithBreaks(Element el) {
    final withBreaks = el.innerHtml.replaceAll(
      RegExp(r'<br\s*/?>', caseSensitive: false),
      '\n',
    );
    return html_parser.parseFragment(withBreaks).text?.trim() ?? '';
  }
}
