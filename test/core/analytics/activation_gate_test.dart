import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/activation_gate.dart';

void main() {
  test('до открытия действия копятся и выполняются по порядку', () {
    final gate = ActivationGate();
    final calls = <int>[];

    gate
      ..run(() => calls.add(1))
      ..run(() => calls.add(2));
    expect(calls, isEmpty);

    gate.open();
    expect(calls, [1, 2]);
  });

  test('после открытия действие выполняется сразу', () {
    final gate = ActivationGate()..open();
    final calls = <int>[];

    gate.run(() => calls.add(1));
    expect(calls, [1]);
  });

  test('повторное открытие не повторяет накопленное', () {
    final gate = ActivationGate();
    var count = 0;

    gate
      ..run(() => count++)
      ..open()
      ..open();
    expect(count, 1);
  });
}
