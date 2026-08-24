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

/// Извлекает полный текст рассказа из блока `.brif` страницы Азбуки.
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

  static List<String> _paragraphsFrom(Element container) {
    // Заголовки и сноски уже не нужны на экране рассказа.
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

  // Element.text не добавляет пробел для <br>.
  static String _textWithBreaks(Element el) {
    final withBreaks = el.innerHtml.replaceAll(
      RegExp(r'<br\s*/?>', caseSensitive: false),
      '\n',
    );
    return html_parser.parseFragment(withBreaks).text?.trim() ?? '';
  }
}
