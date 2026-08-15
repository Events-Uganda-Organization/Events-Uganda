package com.eventsuganda.otp.dto.response;

/**
 * Typed push payload sent to a user's STOMP queue (/queue/calls).
 * Every signal carries a {@code type} plus whichever fields apply to it.
 */
public class CallSignalResponse {

    private String type;
    private String callId;
    private String callerId;
    private String calleeId;
    private String callerName;
    private String calleeName;
    private String sdp;
    private String candidate;
    private Long startedAt;
    private Long durationMs;
    private String message;

    public CallSignalResponse() {}

    public static CallSignalResponse of(String type, String callId) {
        return new CallSignalResponse().type(type).callId(callId);
    }

    public String getType() { return type; }
    public String getCallId() { return callId; }
    public String getCallerId() { return callerId; }
    public String getCalleeId() { return calleeId; }
    public String getCallerName() { return callerName; }
    public String getCalleeName() { return calleeName; }
    public String getSdp() { return sdp; }
    public String getCandidate() { return candidate; }
    public Long getStartedAt() { return startedAt; }
    public Long getDurationMs() { return durationMs; }
    public String getMessage() { return message; }

    public CallSignalResponse type(String v) { this.type = v; return this; }
    public CallSignalResponse callId(String v) { this.callId = v; return this; }
    public CallSignalResponse callerId(String v) { this.callerId = v; return this; }
    public CallSignalResponse calleeId(String v) { this.calleeId = v; return this; }
    public CallSignalResponse callerName(String v) { this.callerName = v; return this; }
    public CallSignalResponse calleeName(String v) { this.calleeName = v; return this; }
    public CallSignalResponse sdp(String v) { this.sdp = v; return this; }
    public CallSignalResponse candidate(String v) { this.candidate = v; return this; }
    public CallSignalResponse startedAt(Long v) { this.startedAt = v; return this; }
    public CallSignalResponse durationMs(Long v) { this.durationMs = v; return this; }
    public CallSignalResponse message(String v) { this.message = v; return this; }
}
