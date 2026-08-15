package com.eventsuganda.otp.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "calls")
public class Call {

    public enum Status {
        RINGING, CONNECTED, ENDED, REJECTED, CANCELLED, NO_ANSWER, UNREACHABLE, BUSY
    }

    @Id
    private String id;

    @Column(nullable = false)
    private String callerId;

    @Column(nullable = false)
    private String calleeId;

    @Column(nullable = false)
    private String status;

    private Long startedAt;

    private Long endedAt;

    private Long durationMs;

    @Column(nullable = false)
    private long createdAt;

    public Call() {}

    public Call(String id, String callerId, String calleeId) {
        this.id = id;
        this.callerId = callerId;
        this.calleeId = calleeId;
        this.status = Status.RINGING.name();
        this.createdAt = System.currentTimeMillis();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getCallerId() { return callerId; }
    public void setCallerId(String callerId) { this.callerId = callerId; }

    public String getCalleeId() { return calleeId; }
    public void setCalleeId(String calleeId) { this.calleeId = calleeId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Long getStartedAt() { return startedAt; }
    public void setStartedAt(Long startedAt) { this.startedAt = startedAt; }

    public Long getEndedAt() { return endedAt; }
    public void setEndedAt(Long endedAt) { this.endedAt = endedAt; }

    public Long getDurationMs() { return durationMs; }
    public void setDurationMs(Long durationMs) { this.durationMs = durationMs; }

    public long getCreatedAt() { return createdAt; }
    public void setCreatedAt(long createdAt) { this.createdAt = createdAt; }
}
