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

/// Извлекает полный текст рассказа из блока `.brif` страницы Азбуки
/// и икону праздника или святого.
class AzbykaDayStoryRemoteDatasource implements DayStoryRemoteDatasource {
  AzbykaDayStoryRemoteDatasource({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const _selector =
      '.holiday-description .brif, .saint-description .brif, '
      '.saints-group-description .brif';

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
    final iconUrl = _iconFrom(doc);
    final container = doc.querySelector(_selector);
    if (container == null) {
      // Не у каждой календарной страницы есть описание в этом формате.
      netLog('на странице рассказа нет описания');
      return const DayStoryDto(paragraphs: []);
    }

    final paragraphs = _paragraphsFrom(container);
    if (paragraphs.isEmpty) {
      netLog('описание праздника/святого пустое');
    }
    netLog('${paragraphs.length} абзацев за ${elapsed.elapsedMilliseconds}мс');
    return DayStoryDto(paragraphs: paragraphs, iconUrl: iconUrl);
  }

  /// Иконы лежат в своих папках хранилища. Фото дня и общая картинка
  /// сайта иконой не считаются.
  static final _iconPath = RegExp(
    r'/storage/images/(icons-of-holidays|icons-of-saints|saints-group)/',
  );

  /// Сначала оригинал из галереи: у соборов святых в og:image стоит общая
  /// картинка сайта, а их икона есть только в галерее. Без галереи берём
  /// уменьшенную копию из og:image.
  static String? _iconFrom(Document doc) {
    final candidates = [
      for (final link in doc.querySelectorAll('a[data-fancybox-href]'))
        link.attributes['data-fancybox-href'],
      doc.querySelector('meta[property="og:image"]')?.attributes['content'],
    ];
    for (final candidate in candidates.nonNulls) {
      if (!_iconPath.hasMatch(candidate)) continue;
      return Uri.parse('https://azbyka.ru/').resolve(candidate).toString();
    }
    return null;
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
