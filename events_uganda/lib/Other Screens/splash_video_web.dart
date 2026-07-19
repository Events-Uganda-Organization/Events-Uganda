import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class SplashVideoPlayer extends StatefulWidget {
  final double screenWidth;
  final VoidCallback? onVideoEnded;
  const SplashVideoPlayer({super.key, required this.screenWidth, this.onVideoEnded});
  @override
  State<SplashVideoPlayer> createState() => _SplashVideoPlayerState();
}

class _SplashVideoPlayerState extends State<SplashVideoPlayer> {
  static bool _registered = false;
  web.HTMLVideoElement? _videoElement;
  JSFunction? _endedListener;

  String _selectVideoAsset(double width) {
    if (width < 600) {
      return 'assets/videos/splash_medium.mp4';
    }
    return 'assets/videos/splash_large.mp4';
  }

  @override
  void initState() {
    super.initState();
    final videoSrc = _selectVideoAsset(widget.screenWidth);
    if (!_registered) {
      _registered = true;
      ui_web.platformViewRegistry.registerViewFactory(
        'splash-video',
        (int viewId) {
          _videoElement =
              web.document.createElement('video') as web.HTMLVideoElement;
          _videoElement!.src = videoSrc;
          _videoElement!.muted = true;
          _videoElement!.loop = false;
          _videoElement!.autoplay = true;
          _videoElement!.playsInline = true;
          _videoElement!.playbackRate = 1.3;
          _videoElement!.onEnded.listen((_) {
            widget.onVideoEnded?.call();
          });
          _videoElement!.style
            ..width = '100%'
            ..height = '100%'
            ..objectFit = 'cover';
          _endedListener = ((web.Event _) {
            widget.onVideoEnded?.call();
          }).toJS;
          _videoElement!.addEventListener('ended', _endedListener);
          return _videoElement!;
        },
      );
    }
  }

  @override
  void dispose() {
    if (_videoElement != null && _endedListener != null) {
      _videoElement!.removeEventListener('ended', _endedListener);
    }
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
