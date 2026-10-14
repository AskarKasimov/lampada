import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/domain/split_day_card_text.dart';

String _sentence(int length, [String end = '.']) => '${'а' * (length - 1)}$end';

void main() {
  test('короткий текст остаётся одной страницей', () {
    const text = 'Первое предложение. Второе предложение.';
    expect(splitDayCardText(text), [text]);
  });

  test('длинный текст делится по предложениям в пределах страницы', () {
    final sentences = List.generate(6, (_) => _sentence(100));
    final pages = splitDayCardText(sentences.join(' '), maxChars: 280);

    expect(pages, hasLength(3));
    for (final page in pages) {
      expect(page.length, lessThanOrEqualTo(280));
    }
    expect(pages.join(' '), sentences.join(' '));
  });

  test('страницы примерно равны, без короткого хвоста', () {
    // 300 символов: две страницы по 150 лучше, чем 280 и 20.
    final sentences = List.generate(6, (_) => _sentence(49));
    final pages = splitDayCardText(sentences.join(' '), maxChars: 280);

    expect(pages, hasLength(2));
    expect(pages.first.length, closeTo(pages.last.length, 50));
  });

  test('вопрос и ответ не склеиваются в одну перегруженную страницу', () {
    final question = _sentence(110, '?');
    final answer = [_sentence(120), _sentence(130)].join(' ');
    final pages = splitDayCardText('$question $answer', maxChars: 280);

    expect(pages, hasLength(2));
    expect(pages.first, question);
    expect(pages.last, answer);
  });

  test('абзацы сохраняются, лишние пробелы по краям страниц убираются', () {
    final first = _sentence(200);
    final second = _sentence(200);
    final pages = splitDayCardText('$first\n\n$second', maxChars: 280);

    expect(pages, [first, second]);
  });

  test('слишком длинное предложение остаётся целым', () {
    final long = _sentence(400);
    final pages = splitDayCardText('$long ${_sentence(50)}', maxChars: 280);

    expect(pages.first, long);
    expect(pages, hasLength(2));
  });

  test('сокращения не разрывают страницу посреди мысли', () {
    final text = '${_sentence(200)} Как учил св. Феофан, ${'б' * 150}.';
    final pages = splitDayCardText(text, maxChars: 280);

    expect(pages.last, startsWith('Как учил св. Феофан'));
  });

  test('пустой текст остаётся пустой страницей', () {
    expect(splitDayCardText(''), ['']);
  });
}
