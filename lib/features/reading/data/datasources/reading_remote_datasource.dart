import 'dart:async';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../../../../core/log/net_log.dart';
import '../../../../core/network/remote_fetch_exception.dart';
import '../../../../core/result/result.dart';
import '../dto/daily_reading_dto.dart';

/// Разобранная ссылка отрывка: `Jn.10:1-9`, `Mt.16:20-17:9`.
class PassageRef {
  const PassageRef({
    required this.book,
    required this.fromChapter,
    required this.fromVerse,
    required this.toChapter,
    required this.toVerse,
  });

  final String book;
  final int fromChapter;
  final int fromVerse;
  final int toChapter;
  final int toVerse;

  static final _pattern = RegExp(
    r'^([A-Za-z0-9]+)\.(\d+):(\d+)(?:-(?:(\d+):)?(\d+))?$',
  );

  /// null, если строка не похожа на ссылку — вызывающий переведёт это в сбой.
  static PassageRef? tryParse(String reference) {
    final m = _pattern.firstMatch(reference.trim());
    if (m == null) return null;
    final fromChapter = int.parse(m.group(2)!);
    final fromVerse = int.parse(m.group(3)!);
    // Межглавный отрывок `16:20-17:9` даёт вторую главу; `10:1-9` — нет.
    final toChapter = m.group(4) == null ? fromChapter : int.parse(m.group(4)!);
    final toVerse = m.group(5) == null ? fromVerse : int.parse(m.group(5)!);
    return PassageRef(
      book: m.group(1)!,
      fromChapter: fromChapter,
      fromVerse: fromVerse,
      toChapter: toChapter,
      toVerse: toVerse,
    );
  }

  bool contains(int chapter, int verse) {
    if (chapter < fromChapter || chapter > toChapter) return false;
    if (chapter == fromChapter && verse < fromVerse) return false;
    if (chapter == toChapter && verse > toVerse) return false;
    return true;
  }
}

abstract interface class ReadingRemoteDatasource {
  Future<DailyReadingDto> fetch(String reference, {required Duration timeout});
}

/// Скрейпит две страницы Азбуки: сам текст отрывка и толкование к нему.
///
/// Толкования на странице Библии нет — там только список ссылок на
/// /otechnik/. Автора не зашиваем в код: ссылку на Феофилакта берём из этого
/// же списка, иначе пришлось бы держать карту «книга → slug книги толкований»
/// и ловить её расхождения с сайтом.
class AzbykaReadingRemoteDatasource implements ReadingRemoteDatasource {
  AzbykaReadingRemoteDatasource({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Толкователь по умолчанию. Феофилакт Болгарский покрывает все четыре
  /// Евангелия и заметно короче Лопухина — на карточке это решает.
  static const _interpreterSlug = 'Feofilakt_Bolgarskij';

  /// Русские сокращения книг — ими Феофилакт размечает стихи в тексте
  /// («Ин.10:1 . …»), тогда как ссылки Азбуки используют латинский slug.
  static const _russianAbbr = {'Mt': 'Мф', 'Mk': 'Мк', 'Lk': 'Лк', 'Jn': 'Ин'};

  @override
  Future<DailyReadingDto> fetch(
    String reference, {
    required Duration timeout,
  }) async {
    final ref = PassageRef.tryParse(reference);
    if (ref == null) {
      netLog('ссылка "$reference" не разобралась → unknown');
      throw RemoteFetchException(
        FailureKind.unknown,
        FormatException('нераспознанная ссылка отрывка: $reference'),
      );
    }

    final elapsed = Stopwatch()..start();
    // `&r` обязателен: без него Азбука на части отрывков отдаёт
    // церковнославянский, и юзер получает нечитаемый для новоначального текст.
    final passageDoc = await _get(
      Uri.parse('https://azbyka.ru/biblia/?$reference&r'),
      timeout,
    );

    final verses = _versesFrom(passageDoc, ref);
    if (verses.isEmpty) {
      netLog('стихи не нашлись на странице отрывка → unknown');
      throw RemoteFetchException(
        FailureKind.unknown,
        const FormatException('на странице отрывка нет стихов'),
      );
    }
    netLog('${verses.length} стихов за ${elapsed.elapsedMilliseconds}мс');

    // Толкование необязательно: без него чтение всё ещё состоятельно,
    // поэтому его сбой день не роняет.
    var withInterpretations = verses;
    String? author;
    final link = _interpreterLink(passageDoc);
    if (link != null) {
      final left = timeout - elapsed.elapsed;
      if (left > const Duration(milliseconds: 500)) {
        try {
          final doc = await _get(Uri.parse(link.href), left);
          final byVerse = _interpretationsByVerse(doc, ref);
          netLog('толкований по стихам: ${byVerse.length}');
          withInterpretations = [
            for (final v in verses)
              byVerse[v.number] == null
                  ? v
                  : v.copyWith(
                      interpretation: byVerse[v.number]!.text,
                      interpretationRange: byVerse[v.number]!.range,
                    ),
          ];
          author = link.author;
        } on Exception catch (e) {
          netLog('толкование не загрузилось, отдаём чтение без него: $e');
        }
      } else {
        netLog('на толкование не осталось времени — отдаём чтение без него');
      }
    }

    return DailyReadingDto(
      label: _labelFor(reference),
      verses: withInterpretations,
      interpretationAuthor: author,
    );
  }

  Future<Document> _get(Uri uri, Duration timeout) async {
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
    return html_parser.parse(response.body);
  }

  /// Страница отдаёт главу целиком — отбираем стихи запрошенного диапазона.
  static List<VerseDto> _versesFrom(Document doc, PassageRef ref) {
    final result = <VerseDto>[];
    for (final el in doc.querySelectorAll('div.verse.lang-r[data-verse]')) {
      final parsed = _numbersOf(el);
      if (parsed == null) continue;
      final (chapter, number) = parsed;
      if (!ref.contains(chapter, number)) continue;

      // «[ Зач. 36. ]» — богослужебная пометка начала зачала, к тексту стиха
      // отношения не имеет и на экране читается как мусор.
      el.querySelectorAll('.zachala').forEach((e) => e.remove());
      el.querySelectorAll('.checkbox').forEach((e) => e.remove());

      final text = el.text
          .replaceAll(RegExp(r'\s+'), ' ')
          // Квадратные скобки вокруг зачала — отдельные текстовые узлы, а не
          // часть спана, поэтому после его удаления от пометки остаётся «[]».
          .replaceFirst(RegExp(r'^\s*\[\s*\]\s*'), '')
          .trim();
      if (text.isEmpty) continue;
      result.add(VerseDto(number: number, chapter: chapter, text: text));
    }
    result.sort(
      (a, b) => a.chapter == b.chapter
          ? a.number.compareTo(b.number)
          : a.chapter.compareTo(b.chapter),
    );
    return result;
  }

  /// `data-verse="Jn.10:1"` → (10, 1).
  static (int, int)? _numbersOf(Element el) {
    final raw = el.attributes['data-verse'] ?? '';
    final m = RegExp(r'\.(\d+):(\d+)$').firstMatch(raw);
    if (m == null) return null;
    return (int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  static ({String href, String author})? _interpreterLink(Document doc) {
    for (final a in doc.querySelectorAll('.interprets a[href]')) {
      final href = a.attributes['href']!;
      if (!href.contains(_interpreterSlug)) continue;
      return (
        href: href.startsWith('http') ? href : 'https://azbyka.ru$href',
        author: a.text.trim(),
      );
    }
    return null;
  }

  /// Толкования, разложенные по номерам стихов.
  ///
  /// Страница толкования устроена пробегами: сначала идут `p.h5` — ссылки на
  /// стихи с их синодальным текстом, затем `p.txt` — комментарий на всю эту
  /// группу сразу. Поэтому группируем структурно, а не нарезкой текста по
  /// маркерам: у Феофилакта на Мф.20 один блок покрывает стихи 1–7, и
  /// нарезка «по стиху» отдала бы юзеру сам стих вместо толкования.
  ///
  /// Стихи группы получают ОДИН общий текст и общую подпись отрывка —
  /// обещать «толкование на этот стих», когда оно написано на семь,
  /// было бы неправдой.
  ///
  /// Межглавный отрывок покрыт только первой главой: страница толкования
  /// одна на главу, а тянуть вторую ради хвоста — ещё один HTTP-поход.
  static Map<int, ({String text, String range})> _interpretationsByVerse(
    Document doc,
    PassageRef ref,
  ) {
    final abbr = _russianAbbr[ref.book];
    if (abbr == null) return const {};

    final result = <int, ({String text, String range})>{};
    var group = <int>[];
    var commentary = <String>[];

    void flush() {
      if (group.isNotEmpty && commentary.isNotEmpty) {
        final range = group.length == 1
            ? '$abbr.${ref.fromChapter}:${group.first}'
            : '$abbr.${ref.fromChapter}:${group.first}–${group.last}';
        final text = commentary.join('\n\n');
        for (final number in group) {
          result[number] = (text: text, range: range);
        }
      }
      group = [];
      commentary = [];
    }

    for (final p in doc.querySelectorAll('p.h5, p.txt')) {
      if (p.classes.contains('h5')) {
        // Стихи после комментария — уже следующая группа.
        if (commentary.isNotEmpty) flush();
        final number = _verseNumberOf(p, ref);
        if (number != null) group.add(number);
      } else {
        final text = p.text.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (text.isNotEmpty) commentary.add(text);
      }
    }
    flush();

    return result;
  }

  /// Номер стиха из ссылки в `p.h5`. Не все `p.h5` её несут — бывают
  /// подзаголовки, их пропускаем.
  static int? _verseNumberOf(Element paragraph, PassageRef ref) {
    for (final a in paragraph.querySelectorAll('a[href]')) {
      final m = RegExp(
        r'\?([A-Za-z0-9]+)\.(\d+):(\d+)',
      ).firstMatch(a.attributes['href']!);
      if (m == null) continue;
      if (m.group(1) != ref.book) continue;
      if (int.parse(m.group(2)!) != ref.fromChapter) continue;
      return int.parse(m.group(3)!);
    }
    return null;
  }

  /// `Jn.10:1-9` → «Ин.10:1–9». Ссылка приходит из карточки дня уже
  /// человекочитаемой, но кэш и тесты зовут датасорс напрямую.
  static String _labelFor(String reference) {
    final ref = PassageRef.tryParse(reference);
    if (ref == null) return reference;
    final abbr = _russianAbbr[ref.book] ?? ref.book;
    final head = '$abbr.${ref.fromChapter}:${ref.fromVerse}';
    if (ref.fromChapter == ref.toChapter && ref.fromVerse == ref.toVerse) {
      return head;
    }
    return ref.fromChapter == ref.toChapter
        ? '$head–${ref.toVerse}'
        : '$head–${ref.toChapter}:${ref.toVerse}';
  }
}
