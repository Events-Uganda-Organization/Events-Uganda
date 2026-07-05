import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashVideoPlayer extends StatefulWidget {
  final double screenWidth;
  const SplashVideoPlayer({super.key, required this.screenWidth});
  @override
  State<SplashVideoPlayer> createState() => _SplashVideoPlayerState();
}

class _SplashVideoPlayerState extends State<SplashVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  String _selectVideoAsset(double width) {
    if (width < 600) {
      return 'assets/videos/splash_medium.mp4';
    }
    return 'assets/videos/splash_large.mp4';
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      _selectVideoAsset(widget.screenWidth),
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
