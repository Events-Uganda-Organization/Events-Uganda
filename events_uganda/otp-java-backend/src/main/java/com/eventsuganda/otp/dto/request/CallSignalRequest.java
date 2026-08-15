package com.eventsuganda.otp.dto.request;

public class CallSignalRequest {

    private String callId;
    private String calleeId;
    private String callerName;
    private String calleeName;
    private String sdp;
    private String candidate;

    public String getCallId() { return callId; }
    public void setCallId(String callId) { this.callId = callId; }

    public String getCalleeId() { return calleeId; }
    public void setCalleeId(String calleeId) { this.calleeId = calleeId; }

    public String getCallerName() { return callerName; }
    public void setCallerName(String callerName) { this.callerName = callerName; }

    public String getCalleeName() { return calleeName; }
    public void setCalleeName(String calleeName) { this.calleeName = calleeName; }

    public String getSdp() { return sdp; }
    public void setSdp(String sdp) { this.sdp = sdp; }

    public String getCandidate() { return candidate; }
    public void setCandidate(String candidate) { this.candidate = candidate; }
}
