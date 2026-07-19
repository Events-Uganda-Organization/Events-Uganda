import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashVideoPlayer extends StatefulWidget {
  final VoidCallback? onVideoEnd;
  const SplashVideoPlayer({super.key, this.onVideoEnd});
  @override
  State<SplashVideoPlayer> createState() => _SplashVideoPlayerState();
}

class _SplashVideoPlayerState extends State<SplashVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/videos/Bride_and_groom_merge_light_202606290000.mp4',
    );
    _controller.initialize().then((_) {
      _controller.setLooping(false);
      _controller.setVolume(0);
      _controller.addListener(_onVideoControllerUpdate);
      _controller.play();
      if (mounted) setState(() => _initialized = true);
    }).catchError((_) {
      if (mounted) setState(() => _initialized = true);
    });
  }

  void _onVideoControllerUpdate() {
    if (!_fired &&
        _controller.value.isInitialized &&
        _controller.value.position >= _controller.value.duration) {
      _fired = true;
      widget.onVideoEnd?.call();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SizedBox.expand(child: ColoredBox(color: Colors.black));
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
