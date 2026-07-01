import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class SplashVideoPlayer extends StatefulWidget {
  const SplashVideoPlayer({super.key});
  @override
  State<SplashVideoPlayer> createState() => _SplashVideoPlayerState();
}

class _SplashVideoPlayerState extends State<SplashVideoPlayer> {
  static bool _registered = false;
  web.HTMLVideoElement? _videoElement;

  @override
  void initState() {
    super.initState();
    if (!_registered) {
      _registered = true;
      ui_web.platformViewRegistry.registerViewFactory(
        'splash-video',
        (int viewId) {
          _videoElement =
              web.document.createElement('video') as web.HTMLVideoElement;
          _videoElement!.src =
              'assets/videos/Bride_and_groom_merge_light_202606290000.mp4';
          _videoElement!.muted = true;
          _videoElement!.loop = false;
          _videoElement!.autoplay = true;
          _videoElement!.playsInline = true;
          _videoElement!.playbackRate = 1.3;
          _videoElement!.style
            ..width = '100%'
            ..height = '100%'
            ..objectFit = 'cover';
          return _videoElement!;
        },
      );
    }
  }

  @override
  void dispose() {
    _videoElement?.pause();
    _videoElement?.removeAttribute('src');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: HtmlElementView(viewType: 'splash-video'),
    );
  }
}
