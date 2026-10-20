import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';

/// Телефон с записью читалки, которая крутится по кругу: показывает
/// механику «одна мысль на экран» вместо того, чтобы обещать её словами.
class ReaderPreview extends StatefulWidget {
  const ReaderPreview({super.key, this.onVideoFailed});

  /// Видео не запустилось: превью остаётся пустым телефоном.
  final VoidCallback? onVideoFailed;

  /// Статус-бар в записи закрашен фоном, а последний кадр плавно переходит
  /// в первый: так на стыке цикла нет рывка.
  static const asset = 'assets/video/reader_preview.mp4';

  @override
  State<ReaderPreview> createState() => _ReaderPreviewState();
}

/// Логический размер макета; на экране он масштабируется целиком. Экран
/// внутри рамки (282×612) повторяет пропорции записи 1206×2622.
const _deviceSize = Size(300, 630);

/// Фон записи: виден, пока плеер не отдал первый кадр.
const _videoBackground = Color(0xFFF7EBDA);

class _ReaderPreviewState extends State<ReaderPreview> {
  // Без звука и без захвата аудиосессии: онбординг не должен останавливать
  // музыку или подкаст и не должен мешать экрану гаснуть.
  final _controller = VideoPlayerController.asset(
    ReaderPreview.asset,
    videoPlayerOptions: VideoPlayerOptions(
      mixWithOthers: true,
      preventsDisplaySleepDuringVideoPlayback: false,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _start(reduceMotion: MediaQuery.disableAnimationsOf(context));
  }

  Future<void> _start({required bool reduceMotion}) async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0);
      // С «Уменьшением движения» остаётся первый кадр: читалка видна,
      // но ничего не движется.
      if (!reduceMotion) await _controller.play();
    } catch (_) {
      // Без видео остаётся пустой экран телефона: онбординг важнее превью.
      widget.onVideoFailed?.call();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      image: true,
      label: 'Пример читалки: стихи листаются по одному',
      child: ExcludeSemantics(
        child: FittedBox(
          child: SizedBox.fromSize(size: _deviceSize, child: _device(context)),
        ),
      ),
    );
  }

  Widget _device(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final video = _controller.value;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1411),
        borderRadius: BorderRadius.circular(48),
        // В тёмной теме корпус почти совпадает с фоном: контур его очерчивает.
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: colors.chipUnreadBorder, width: 1.5)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(39),
          child: ColoredBox(
            color: _videoBackground,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (video.isInitialized)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox.fromSize(
                      size: video.size,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                const Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(child: _Island()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Island extends StatelessWidget {
  const _Island();

  @override
  Widget build(BuildContext context) => Container(
    width: 92,
    height: 26,
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(13),
    ),
  );
}
