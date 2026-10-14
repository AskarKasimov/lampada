import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/widgets/app_primary_button.dart';

void main() {
  testWidgets('основная кнопка — скруглённый прямоугольник, не капсула', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPrimaryButton(
            label: 'Готово',
            color: Colors.brown,
            onPressed: () {},
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final shape = button.style!.shape!.resolve({});
    expect(
      shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    );
  });
}
