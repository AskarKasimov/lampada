import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/widgets/app_share_button.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

class _RecordingSharePlatform extends SharePlatform {
  ShareParams? params;

  @override
  Future<ShareResult> share(ShareParams params) async {
    this.params = params;
    return ShareResult.unavailable;
  }
}

void main() {
  testWidgets('добавляет ссылки на магазины в отправленный материал', (
    tester,
  ) async {
    final originalPlatform = SharePlatform.instance;
    final platform = _RecordingSharePlatform();
    SharePlatform.instance = platform;
    addTearDown(() => SharePlatform.instance = originalPlatform);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (_) => const AppShareButton(text: 'Текст материала'),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byTooltip('Поделиться')), const Size(40, 40));

    await tester.tap(find.byTooltip('Поделиться'));
    await tester.pump();

    expect(
      platform.params?.text,
      'Текст материала\n\n'
      'Приложение Лампада:\n'
      'App Store: https://clck.su/gXEhl\n'
      'RuStore: https://clck.su/hdeZJ',
    );
    expect(platform.params?.sharePositionOrigin, isNotNull);
  });
}
