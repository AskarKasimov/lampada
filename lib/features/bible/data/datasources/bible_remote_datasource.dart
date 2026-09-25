import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../../../../core/network/remote_fetch_exception.dart';
import '../../../../core/result/result.dart';
import '../dto/bible_chapter_dto.dart';

abstract interface class BibleRemoteDatasource {
  Future<BibleChapterDto> fetchChapter(String book, int chapter);
}

class AzbykaBibleRemoteDatasource implements BibleRemoteDatasource {
  AzbykaBibleRemoteDatasource({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<BibleChapterDto> fetchChapter(String book, int chapter) async {
    final uri = Uri.parse('https://azbyka.ru/biblia/?$book.$chapter&r');
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
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

    final document = html_parser.parse(utf8.decode(response.bodyBytes));
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
          .querySelectorAll('.checkbox, .zachala')
          .forEach((node) => node.remove());
      final text = element.text.replaceAll(RegExp(r'\s+'), ' ').trim();
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
    return BibleChapterDto(book: book, number: chapter, verses: verses);
  }
}
