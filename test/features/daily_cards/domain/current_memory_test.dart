import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/domain/current_memory.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_memory.dart';

const _foma = DayMemory(title: 'Прп. Фомы', storyUrl: 'https://a/foma');
const _akakij = DayMemory(title: 'Прп. Акакия', storyUrl: 'https://a/akakij');
const _kiriakija = DayMemory(
  title: 'Мц. Кириакии',
  storyUrl: 'https://a/kiriakija',
);
const _memories = [_foma, _akakij, _kiriakija];

void main() {
  test('без памятей показывать нечего', () {
    expect(currentMemory(const [], const {}), isNull);
  });

  test('ничего не прочитано: первая память дня', () {
    expect(currentMemory(_memories, const {}), (memory: _foma, isRead: false));
  });

  test('после первого святого плитка показывает следующего', () {
    expect(currentMemory(_memories, {_foma.storyUrl}), (
      memory: _akakij,
      isRead: false,
    ));
  });

  test('берётся первый непрочитанный, даже если читали не по порядку', () {
    expect(currentMemory(_memories, {_akakij.storyUrl}), (
      memory: _foma,
      isRead: false,
    ));
    expect(currentMemory(_memories, {_foma.storyUrl, _akakij.storyUrl}), (
      memory: _kiriakija,
      isRead: false,
    ));
  });

  test('все прочитаны: снова первый, уже прочитанным', () {
    expect(currentMemory(_memories, {for (final m in _memories) m.storyUrl}), (
      memory: _foma,
      isRead: true,
    ));
  });
}
