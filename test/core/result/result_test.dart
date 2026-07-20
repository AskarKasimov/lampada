import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';

void main() {
  test('AppFailure несёт вид ошибки и печатает его в toString', () {
    const failure = AppFailure('нет сети', kind: FailureKind.network);

    expect(failure.kind, FailureKind.network);
    expect(failure.toString(), contains('network'));
  });
}
