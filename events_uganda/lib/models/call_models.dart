/// Call state machine mirroring the backend's Call.Status + signals.
enum CallStatus {
  idle,
  outgoing, // caller, waiting for callee to answer (ringing)
  incoming, // callee, phone ringing
  connecting, // accept was tapped, establishing media
  active, // media connected, timer running
  ended,
  rejected,
  cancelled,
  noAnswer,
  busy,
  unreachable,
}

enum CallRole { caller, callee }

/// Typed payload pushed to the user's STOMP queue (/user/queue/calls).
/// Field names match backend CallSignalResponse.
class CallSignal {
  const CallSignal({
    required this.type,
    this.callId,
    this.callerId,
    this.calleeId,
    this.callerName,
    this.calleeName,
    this.sdp,
    this.candidate,
    this.startedAt,
    this.durationMs,
    this.message,
  });

  final String type;
  final String? callId;
  final String? callerId;
  final String? calleeId;
  final String? callerName;
  final String? calleeName;
  final String? sdp;
  final String? candidate;
  final int? startedAt;
  final int? durationMs;
  final String? message;

  bool get isTerminal =>
      type == 'call.rejected' ||
      type == 'call.cancelled' ||
      type == 'call.noanswer' ||
      type == 'call.unreachable' ||
      type == 'call.busy' ||
      type == 'call.ended';

  factory CallSignal.fromJson(Map<String, dynamic> json) => CallSignal(
        type: json['type'] as String? ?? '',
        callId: json['callId'] as String?,
        callerId: json['callerId'] as String?,
        calleeId: json['calleeId'] as String?,
        callerName: json['callerName'] as String?,
        calleeName: json['calleeName'] as String?,
        sdp: json['sdp'] as String?,
        candidate: json['candidate'] as String?,
        startedAt: (json['startedAt'] as num?)?.toInt(),
        durationMs: (json['durationMs'] as num?)?.toInt(),
        message: json['message'] as String?,
      );
}
