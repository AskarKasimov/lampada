import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../../../../core/azbyka/azbyka_interpretations.dart';
import '../../../../core/log/net_log.dart';
import '../../../../core/network/remote_fetch_exception.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/bible_book.dart';
import '../dto/bible_chapter_dto.dart';

abstract interface class BibleRemoteDatasource {
  Future<BibleChapterDto> fetchChapter(String book, int chapter);
}

class AzbykaBibleRemoteDatasource implements BibleRemoteDatasource {
  AzbykaBibleRemoteDatasource({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  // Глава получает прежние 10 секунд, толкование — остаток общего бюджета.
  static const _budget = Duration(seconds: 12);
  static const _chapterTimeout = Duration(seconds: 10);
  static const _minInterpretationTime = Duration(milliseconds: 500);

  // Феофилакт — как в чтении дня; у Ветхого Завета и Откровения его нет,
  // а Толковая Библия Лопухина покрывает все книги.
  static const _interpreterSlugs = ['Feofilakt_Bolgarskij', 'Lopuhin'];

  @override
  Future<BibleChapterDto> fetchChapter(String book, int chapter) async {
    final elapsed = Stopwatch()..start();
    final document = await _get(
      Uri.parse('https://azbyka.ru/biblia/?$book.$chapter&r'),
      _chapterTimeout,
    );
    final verses = <BibleVerseDto>[];
    for (final element in document.querySelectorAll(
      'div.verse.lang-r[data-verse]',
    )) {
      final reference = element.attributes['data-verse'];
      final match = RegExp(
        r'^([A-Za-z0-9]+)\.(\d+):(\d+)$',
      ).firstMatch(reference ?? '');
      if (match == null ||
          match.group(1) != book ||
          int.parse(match.group(2)!) != chapter) {
        continue;
      }
      element
          .querySelectorAll('.checkbox, .zachala, .info[aria-hidden]')
          .forEach((node) => node.remove());
      // Скобки вокруг зачала остаются после удаления его узла; это пометка
      // сайта, а непустые скобки Синодального перевода сохраняем.
      final text = element.text
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceFirst(RegExp(r'^\s*\[\s*\]\s*'), '')
          .trim();
      if (text.isEmpty) continue;
      verses.add(BibleVerseDto(number: int.parse(match.group(3)!), text: text));
    }
    verses.sort((a, b) => a.number.compareTo(b.number));
    if (verses.isEmpty) {
      throw RemoteFetchException(
        FailureKind.unknown,
        const FormatException('на странице нет синодальных стихов'),
      );
    }
    final dto = BibleChapterDto(
      book: book,
      number: chapter,
      verses: verses,
      interpretationsChecked: true,
    );

    final link = AzbykaInterpretations.interpreterLink(
      document,
      _interpreterSlugs,
    );
    if (link == null) return dto;
    final left = _budget - elapsed.elapsed;
    // Сбой толкования не должен скрывать саму главу.
    if (left < _minInterpretationTime) {
      netLog('на толкование $book.$chapter не осталось времени');
      return dto.copyWith(interpretationsChecked: false);
    }
    try {
      final byVerse = AzbykaInterpretations.byVerse(
        await _get(Uri.parse(link.href), left),
        book: book,
        chapter: chapter,
        abbreviation:
            bibleBooks
                .where((item) => item.code == book)
                .firstOrNull
                ?.abbreviation ??
            book,
      );
      return dto.copyWith(
        verses: [
          for (final verse in verses)
            byVerse[verse.number] == null
                ? verse
                : verse.copyWith(
                    interpretation: byVerse[verse.number]!.text,
                    interpretationRange: byVerse[verse.number]!.range,
                  ),
        ],
        interpretationAuthor: link.author,
      );
    } on Exception catch (error) {
      netLog('толкование $book.$chapter не загрузилось: $error');
      return dto.copyWith(interpretationsChecked: false);
    }
  }

  Future<Document> _get(Uri uri, Duration timeout) async {
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException catch (error) {
      throw RemoteFetchException(FailureKind.network, error);
    } on SocketException catch (error) {
      throw RemoteFetchException(FailureKind.network, error);
    } on http.ClientException catch (error) {
      throw RemoteFetchException(FailureKind.network, error);
    }
    if (response.statusCode != 200) {
      throw RemoteFetchException(
        FailureKind.server,
        HttpException('azbyka.ru вернул ${response.statusCode}', uri: uri),
      );
    }
    return html_parser.parse(utf8.decode(response.bodyBytes));
  }
}
