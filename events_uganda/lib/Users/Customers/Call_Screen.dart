import 'dart:async';

import 'package:events_uganda/Services/call_service.dart';
import 'package:events_uganda/models/call_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

/// Full-screen voice call UI.
///
/// Reads all state from [CallService.instance] so the screen and the global
/// overlay can never disagree. Handles: incoming accept/decline, caller
/// cancel, active-call mute/speaker/end, and a brief terminal summary.
class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  Timer? _terminalPop;
  bool _popped = false;

  CallService get service => CallService.instance;

  @override
  void initState() {
    super.initState();
    service.openCallScreen();
    service.status.addListener(_maybeScheduleTerminalPop);
  }

  @override
  void dispose() {
    service.status.removeListener(_maybeScheduleTerminalPop);
    _terminalPop?.cancel();
    service.closeCallScreen();
    super.dispose();
  }

  void _maybeScheduleTerminalPop() {
    final status = service.status.value;
    final terminal = status == CallStatus.ended ||
        status == CallStatus.rejected ||
        status == CallStatus.cancelled ||
        status == CallStatus.noAnswer ||
        status == CallStatus.busy ||
        status == CallStatus.unreachable;
    if (!terminal || _popped) return;
    _terminalPop?.cancel();
    _terminalPop = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _popped = true;
        Navigator.of(context).pop();
      }
    });
  }

  String _statusLabel(CallStatus status) {
    switch (status) {
      case CallStatus.outgoing:
        return 'Ringing…';
      case CallStatus.incoming:
        return 'Incoming voice call…';
      case CallStatus.connecting:
        return 'Connecting…';
      case CallStatus.active:
        return _formatElapsed(service.elapsed.value);
      case CallStatus.ended:
        return 'Call ended • ${_formatElapsed(service.elapsed.value)}';
      case CallStatus.rejected:
        return 'Declined';
      case CallStatus.cancelled:
        return 'Cancelled';
      case CallStatus.noAnswer:
        return 'No answer';
      case CallStatus.busy:
        return 'Busy';
      case CallStatus.unreachable:
        return 'Unavailable';
      case CallStatus.idle:
        return '';
    }
  }

  String _formatElapsed(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  bool get _terminal => !service.inCall;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _terminal,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final s = service.status.value;
        if (s == CallStatus.incoming) {
          service.declineCall();
        } else if (s == CallStatus.outgoing) {
          service.cancelCall();
        } else if (s == CallStatus.connecting || s == CallStatus.active) {
          service.closeCallScreen();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1021),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B1F3A), Color(0xFF0D1021)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                _Avatar(name: service.peerName.value ?? ''),
                const SizedBox(height: 24),
                ValueListenableBuilder<String?>(
                  valueListenable: service.peerName,
                  builder: (_, name, __) => Text(
                    name ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<CallStatus>(
                  valueListenable: service.status,
                  builder: (_, status, __) => ValueListenableBuilder<Duration>(
                    valueListenable: service.elapsed,
                    builder: (_, elapsed, ___) => Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: status == CallStatus.active
                            ? const Color(0xFF25D366)
                            : Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                ValueListenableBuilder<CallStatus>(
                  valueListenable: service.status,
                  builder: (_, status, __) => _buildActions(context, status),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, CallStatus status) {
    if (_terminal) {
      return _RoundButton(
        icon: Icons.close,
        color: Colors.white24,
        onTap: () => Navigator.of(context).pop(),
      );
    }

    if (status == CallStatus.incoming) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RoundButton(
            icon: Icons.call,
            color: const Color(0xFF25D366),
            size: 64,
            onTap: () => service.acceptCall(),
          ),
          const SizedBox(width: 56),
          _RoundButton(
            icon: Icons.call_end,
            color: const Color(0xFFE53935),
            size: 64,
            onTap: () => service.declineCall(),
          ),
        ],
      );
    }

    if (status == CallStatus.outgoing || status == CallStatus.connecting) {
      return _RoundButton(
        icon: Icons.call_end,
        color: const Color(0xFFE53935),
        size: 64,
        onTap: () => service.cancelCall(),
      );
    }

    // Active call controls.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RoundButton(
          icon: service.micMuted.value ? Icons.mic_off : Icons.mic,
          color: service.micMuted.value ? const Color(0xFFFFB74D) : Colors.white24,
          onTap: () => service.toggleMic(),
        ),
        const SizedBox(
          width: 64,
          height: 64,
          child: webrtc.RTCVideoView(
            service.remoteRenderer,
            objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
          ),
        ),
        _RoundButton(
          icon: service.speakerOn.value ? Icons.volume_up : Icons.volume_off,
          color: service.speakerOn.value ? const Color(0xFF25D366) : Colors.white24,
          onTap: () => service.toggleSpeaker(),
        ),
        const SizedBox(width: 16),
        _RoundButton(
          icon: Icons.call_end,
          color: const Color(0xFFE53935),
          size: 64,
          onTap: () => service.endCall(),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    if (parts.length == 1) return first.toUpperCase();
    return (first + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        color: Color(0xFF3A3F63),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 44,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 56,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: size * 0.45),
        ),
      ),
    );
  }
}
