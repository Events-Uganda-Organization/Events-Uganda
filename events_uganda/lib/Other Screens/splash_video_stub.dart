import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashVideoPlayer extends StatefulWidget {
  const SplashVideoPlayer({super.key});
  @override
  State<SplashVideoPlayer> createState() => _SplashVideoPlayerState();
}

class _SplashVideoPlayerState extends State<SplashVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/videos/Bride_and_groom_merge_light_202606290000.mp4',
    );
    _controller.initialize().then((_) {
      _controller.setLooping(false);
      _controller.setVolume(0);
      _controller.play();
      if (mounted) setState(() => _initialized = true);
    }).catchError((_) {
      if (mounted) setState(() => _initialized = true);
    });
  }

  @override
  void dispose() {
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
