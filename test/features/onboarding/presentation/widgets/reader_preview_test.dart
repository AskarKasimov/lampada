import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/onboarding/presentation/widgets/reader_preview.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  late _FakeVideoPlatform platform;

  setUp(() {
    platform = _FakeVideoPlatform();
    VideoPlayerPlatform.instance = platform;
  });

  Widget app({bool reduceMotion = false, VoidCallback? onVideoFailed}) =>
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(
            body: Center(child: ReaderPreview(onVideoFailed: onVideoFailed)),
          ),
        ),
      );

  testWidgets('сообщает, если видео не запустилось', (tester) async {
    // Без события не узнать, что плеер не заводится на каких-то Android.
    platform.failCreate = true;
    var failed = false;
    await tester.pumpWidget(app(onVideoFailed: () => failed = true));
    await tester.pumpAndSettle();

    expect(failed, isTrue);
  });

  testWidgets('крутит запись читалки по кругу без звука', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(platform.source?.asset, ReaderPreview.asset);
    expect(platform.looping, isTrue);
    expect(platform.volume, 0);
    expect(platform.playing, isTrue);
    expect(find.byKey(_FakeVideoPlatform.viewKey), findsOneWidget);
  });

  testWidgets('не прерывает музыку и не держит экран включённым', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(platform.mixWithOthers, isTrue);
    expect(platform.preventsDisplaySleep, isFalse);
  });

  testWidgets('при «Уменьшении движения» показывает первый кадр', (
    tester,
  ) async {
    await tester.pumpWidget(app(reduceMotion: true));
    await tester.pumpAndSettle();

    expect(find.byKey(_FakeVideoPlatform.viewKey), findsOneWidget);
    expect(platform.playing, isFalse);
  });

  testWidgets('освобождает плеер вместе с экраном', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    // Контроллер освобождает плеер асинхронно, вне фейкового времени теста.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    expect(platform.disposed, isTrue);
  });

  testWidgets('для скринридера это одна картинка с описанием', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp('Пример')), findsOneWidget);
    semantics.dispose();
  });
}

class _FakeVideoPlatform extends VideoPlayerPlatform {
  static const viewKey = ValueKey('fake-video-view');

  DataSource? source;
  bool? mixWithOthers;
  bool? preventsDisplaySleep;
  bool? looping;
  double? volume;
  bool playing = false;
  bool disposed = false;
  bool failCreate = false;

  @override
  Future<void> init() async {}

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async =>
      this.mixWithOthers = mixWithOthers;

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    if (failCreate) throw Exception('плеер недоступен');
    source = options.dataSource;
    return 1;
  }

  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(
    int playerId,
    bool preventsDisplaySleepDuringVideoPlayback,
  ) async => preventsDisplaySleep = preventsDisplaySleepDuringVideoPlayback;

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    late final StreamController<VideoEvent> events;
    events = StreamController<VideoEvent>(
      onListen: () => events.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 10),
          size: const Size(600, 1304),
        ),
      ),
    );
    return events.stream;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async =>
      this.looping = looping;

  @override
  Future<void> setVolume(int playerId, double volume) async =>
      this.volume = volume;

  @override
  Future<void> play(int playerId) async => playing = true;

  @override
  Future<void> pause(int playerId) async => playing = false;

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Future<void> dispose(int playerId) async => disposed = true;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.expand(key: viewKey);
}
