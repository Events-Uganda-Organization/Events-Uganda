import 'dart:async';
import 'dart:convert';

import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/models/call_models.dart';
import 'package:events_uganda/Services/call_signaling_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:just_audio/just_audio.dart';

/// Singleton orchestrator for voice calls.
///
/// Owns the call state machine (CallStatus), the WebRTC peer connection and
/// the single source of truth timer ([elapsed]). Screens and the global
/// [CallOverlay] observe the exposed ValueNotifiers, so they can never
/// disagree on the current call state.
///
/// Media engine is platform WebRTC via flutter_webrtc (no service, no fees);
/// signaling is fully our own over the existing STOMP WebSocket.
class CallService {
  CallService._();

  static final CallService instance = CallService._();

  static const List<Map<String, dynamic>> _iceServers = [
    {'urls': ['stun:stun.l.google.com:19302']},
  ];

  // ─── Observable state ─────────────────────────────
  final ValueNotifier<CallStatus> status = ValueNotifier(CallStatus.idle);
  final ValueNotifier<String?> peerName = ValueNotifier(null);
  final ValueNotifier<String?> peerId = ValueNotifier(null);
  final ValueNotifier<String?> callId = ValueNotifier(null);
  final ValueNotifier<bool> micMuted = ValueNotifier(false);
  final ValueNotifier<bool> speakerOn = ValueNotifier(false);
  final ValueNotifier<bool> callScreenOpen = ValueNotifier(false);
  final ValueNotifier<Duration> elapsed = ValueNotifier(Duration.zero);

  // ─── Internal state ───────────────────────────────
  CallRole? _role;
  String? _incomingOfferSdp;
  webrtc.RTCPeerConnection? _pc;
  webrtc.MediaStream? _localStream;
  final webrtc.RTCVideoRenderer remoteRenderer = webrtc.RTCVideoRenderer();
  AudioPlayer? _tonePlayer;
  Timer? _ticker;
  DateTime? _tickerBase;
  StreamSubscription<CallSignal>? _subscription;
  bool _initialized = false;

  String get roleName => _role?.name ?? '';

  /// Subscribes to incoming signals. Call once from main().
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await remoteRenderer.initialize();
    } catch (_) {}
    _subscription = CallSignalingService.instance.signals.listen(_onSignal);
  }

  bool get inCall =>
      status.value == CallStatus.outgoing ||
      status.value == CallStatus.incoming ||
      status.value == CallStatus.connecting ||
      status.value == CallStatus.active;

  // ─── Caller ───────────────────────────────────────

  /// Dials [peerId]. [peerName] is shown to the callee.
  Future<void> startCall({
    required String peerId,
    required String peerName,
  }) async {
    if (inCall || peerId.isEmpty) return;
    await CallSignalingService.instance.ensureConnected();
    if (!CallSignalingService.instance.isActive) {
      status.value = CallStatus.unreachable;
      return;
    }

    _role = CallRole.caller;
    this.peerId.value = peerId;
    this.peerName.value = peerName;
    callId.value = null;
    micMuted.value = false;
    speakerOn.value = false;
    elapsed.value = Duration.zero;
    status.value = CallStatus.outgoing;
    await _startTone('assets/audio/ringback.wav');

    try {
      await _ensureMedia();
      final offer = await _pc!.createOffer();
      await _pc!.setLocalDescription(offer);
      final user = await AuthService.getUser();
      final myName = (user?['fullName'] as String?)?.trim();
      CallSignalingService.instance.send('dial', {
        'calleeId': peerId,
        'callerName': (myName == null || myName.isEmpty) ? 'Caller' : myName,
        'sdp': offer.sdp,
      });
    } catch (e) {
      debugPrint('CallService startCall failed: $e');
      await _cleanup();
      status.value = CallStatus.unreachable;
    }
  }

  /// Caller hangs up while ringing.
  Future<void> cancelCall() async {
    final id = callId.value;
    if (id != null && id.isNotEmpty) {
      CallSignalingService.instance.send('cancel', {'callId': id});
    }
    await _stopTone();
    status.value = CallStatus.cancelled;
    await _cleanup();
  }

  // ─── Callee ───────────────────────────────────────

  Future<void> acceptCall() async {
    if (_role != CallRole.callee) return;
    await _stopTone();
    status.value = CallStatus.connecting;

    try {
      await _ensureMedia();
      if (_incomingOfferSdp == null || _incomingOfferSdp!.isEmpty) {
        await _cleanup();
        status.value = CallStatus.ended;
        return;
      }
      await _pc!.setRemoteDescription(
        webrtc.RTCSessionDescription(_incomingOfferSdp!, 'offer'),
      );
      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);
      CallSignalingService.instance.send('accept', {
        'callId': callId.value,
        'sdp': answer.sdp,
      });
    } catch (e) {
      debugPrint('CallService acceptCall failed: $e');
      await _cleanup();
      status.value = CallStatus.ended;
    }
  }

  Future<void> declineCall() async {
    final id = callId.value;
    if (id != null && id.isNotEmpty) {
      CallSignalingService.instance.send('reject', {'callId': id});
    }
    await _stopTone();
    status.value = CallStatus.rejected;
    await _cleanup();
  }

  // ─── Both parties ─────────────────────────────────

  /// Ends an active call (or cancels/declines a ringing one).
  Future<void> endCall() async {
    final id = callId.value;
    if (id != null && id.isNotEmpty) {
      CallSignalingService.instance.send('end', {'callId': id});
    }
    await _stopTone();
    status.value = CallStatus.ended;
    await _cleanup();
  }

  Future<void> toggleMic() async {
    if (_localStream == null) return;
    final tracks = _localStream!.getAudioTracks();
    for (final track in tracks) {
      track.enabled = !track.enabled;
    }
    micMuted.value = tracks.isNotEmpty ? !tracks.first.enabled : micMuted.value;
  }

  Future<void> toggleSpeaker() async {
    speakerOn.value = !speakerOn.value;
    try {
      await webrtc.Helper.setSpeakerphoneOn(speakerOn.value);
    } catch (_) {
      // Not supported on all platforms; silence the failure.
    }
  }

  /// Opens a CallScreen for the current call.
  void openCallScreen() {
    callScreenOpen.value = true;
  }

  /// Closes the CallScreen (call keeps running in the background overlay).
  void closeCallScreen() {
    callScreenOpen.value = false;
  }

  // ─── Signal handling ──────────────────────────────

  void _onSignal(CallSignal s) {
    if (s.callId != null && callId.value != null && s.callId != callId.value) {
      return;
    }

    switch (s.type) {
      case 'call.incoming':
        _onIncoming(s);
      case 'call.ringing':
        if (s.callId != null) callId.value = s.callId;
      case 'call.accepted':
        _onAccepted(s);
      case 'call.ice':
        _onIce(s);
      case 'call.sdp':
        _onSdp(s);
      case 'call.rejected':
        _terminal(CallStatus.rejected);
      case 'call.cancelled':
        _terminal(CallStatus.cancelled);
      case 'call.noanswer':
        _terminal(CallStatus.noAnswer);
      case 'call.busy':
        _terminal(CallStatus.busy);
      case 'call.unreachable':
        _terminal(CallStatus.unreachable);
      case 'call.ended':
        _onRemoteEnded(s);
    }
  }

  void _onIncoming(CallSignal s) {
    if (inCall) return;
    _role = CallRole.callee;
    callId.value = s.callId;
    peerId.value = s.callerId;
    peerName.value = s.callerName;
    _incomingOfferSdp = s.sdp;
    micMuted.value = false;
    speakerOn.value = false;
    elapsed.value = Duration.zero;
    status.value = CallStatus.incoming;
    _startTone('assets/audio/ringtone.wav');
  }

  void _onAccepted(CallSignal s) {
    if (_role == CallRole.caller) {
      _stopTone();
      if (s.sdp != null && s.sdp!.isNotEmpty) {
        try {
          _pc!.setRemoteDescription(webrtc.RTCSessionDescription(s.sdp!, 'answer'));
        } catch (_) {}
      }
    } else {
      _stopTone();
    }
    if (s.startedAt != null) {
      _tickerBase = DateTime.fromMillisecondsSinceEpoch(s.startedAt!);
    }
    status.value = CallStatus.active;
    _startTicker();
  }

  void _onIce(CallSignal s) {
    final raw = s.candidate;
    if (raw == null || raw.isEmpty || _pc == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _pc!.addIceCandidate(webrtc.RTCIceCandidate(
        map['candidate'] as String,
        map['sdpMid'] as String?,
        (map['sdpMLineIndex'] as num?)?.toInt(),
      ));
    } catch (e) {
      debugPrint('CallService addIceCandidate failed: $e');
    }
  }

  void _onSdp(CallSignal s) {
    if (s.sdp == null || s.sdp!.isEmpty || _pc == null) return;
    try {
      _pc!.setRemoteDescription(webrtc.RTCSessionDescription(s.sdp!, 'offer'));
    } catch (_) {}
  }

  void _onRemoteEnded(CallSignal s) {
    _stopTone();
    if (s.durationMs != null) {
      elapsed.value = Duration(milliseconds: s.durationMs!);
    }
    status.value = CallStatus.ended;
    _cleanup();
  }

  void _terminal(CallStatus terminal) {
    _stopTone();
    if (terminal == CallStatus.busy || terminal == CallStatus.unreachable) {
      elapsed.value = Duration.zero;
    }
    status.value = terminal;
    _cleanup();
  }

  // ─── WebRTC media ─────────────────────────────────

  Future<void> _ensureMedia() async {
    if (_pc != null) return;
    _localStream =
        await webrtc.navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});

    _pc = await webrtc.createPeerConnection({'iceServers': _iceServers});
    _pc!.addStream(_localStream!);
    _pc!.onIceCandidate = (candidate) {
      if (candidate == null || candidate.candidate == null) return;
      final id = callId.value;
      if (id == null || id.isEmpty) return;
      CallSignalingService.instance.send('ice', {
        'callId': id,
        'candidate': jsonEncode({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        }),
      });
    };
    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
      } else if (event.track != null) {
        final stream = webrtc.MediaStream();
        stream.addTrack(event.track!);
        remoteRenderer.srcObject = stream;
      }
    };
  }

  Future<void> _cleanup() async {
    _ticker?.cancel();
    _ticker = null;
    _tickerBase = null;
    try {
      _localStream?.getTracks().forEach((t) => t.stop());
      _localStream?.dispose();
    } catch (_) {}
    _localStream = null;
    try {
      remoteRenderer.srcObject = null;
    } catch (_) {}
    try {
      _pc?.close();
    } catch (_) {}
    _pc = null;
    _incomingOfferSdp = null;
    callId.value = null;
    _role = null;
    await _stopTone();
  }

  // ─── Timer ────────────────────────────────────────

  void _startTicker() {
    _ticker?.cancel();
    _tickerBase ??= DateTime.now();
    elapsed.value = Duration.zero;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final base = _tickerBase ?? DateTime.now();
      elapsed.value = DateTime.now().difference(base);
    });
  }

  // ─── Tones ────────────────────────────────────────

  Future<void> _startTone(String asset) async {
    await _stopTone();
    try {
      final player = AudioPlayer();
      _tonePlayer = player;
      await player.setLoopMode(LoopMode.one);
      await player.setAsset(asset);
      await player.play();
    } catch (e) {
      debugPrint('CallService tone failed: $e');
    }
  }

  Future<void> _stopTone() async {
    final player = _tonePlayer;
    _tonePlayer = null;
    if (player == null) return;
    try {
      await player.stop();
      await player.dispose();
    } catch (_) {}
  }
}
