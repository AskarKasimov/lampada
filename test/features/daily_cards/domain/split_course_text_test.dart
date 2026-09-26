import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/domain/split_course_text.dart';

void main() {
  test('каждое предложение становится отдельной карточкой', () {
    expect(splitCourseText('Первое. Второе! Третье?'), [
      'Первое. ',
      'Второе! ',
      'Третье?',
    ]);
  });
  test('перенос внутри предложения не разрывает его', () {
    expect(splitCourseText('Первая строка\nпродолжается\n\nи заканчивается.'), [
      'Первая строка\nпродолжается\n\nи заканчивается.',
    ]);
  });
  test('перенос между предложениями сохраняется', () {
    const text = 'Первое.\n\nВторое.';
    expect(splitCourseText(text), ['Первое.\n\n', 'Второе.']);
  });
  test('длинное предложение остаётся целым', () {
    final text = '${List.filled(60, 'Слово').join(' ')}.';
    expect(splitCourseText(text), [text]);
  });
  test('закрывающие кавычки и многоточие относятся к предложению', () {
    const text = 'Он сказал: «Читайте!» Потом задумался… И продолжил.';
    expect(splitCourseText(text), [
      'Он сказал: «Читайте!» ',
      'Потом задумался… ',
      'И продолжил.',
    ]);
  });
  test('сокращения и десятичные числа не заканчивают предложение', () {
    const text = 'Св. Иоанн писал об этом, т. е. пояснял мысль. Число 3.14.';
    expect(splitCourseText(text), [
      'Св. Иоанн писал об этом, т. е. пояснял мысль. ',
      'Число 3.14.',
    ]);
  });
  test('текст без знака конца и unicode сохраняются', () {
    expect(splitCourseText('Тема 🙏'), ['Тема 🙏']);
    expect(splitCourseText(''), ['']);
  });
}
