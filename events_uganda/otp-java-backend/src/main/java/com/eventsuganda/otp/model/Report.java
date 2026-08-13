package com.eventsuganda.otp.model;

import jakarta.persistence.*;

@Entity
@Table(name = "reports")
public class Report {

    @Id
    private String id;

    @Column(nullable = false)
    private String reporterId;

    @Column(nullable = false)
    private String reportedId;

    private String conversationId;

    private String reason;

    @Column(nullable = false)
    private String status = "PENDING";

    @Column(nullable = false)
    private long createdAt;

    public Report() {}

    public Report(String reporterId, String reportedId, String conversationId, String reason) {
        this.id = java.util.UUID.randomUUID().toString();
        this.reporterId = reporterId;
        this.reportedId = reportedId;
        this.conversationId = conversationId;
        this.reason = reason;
        this.status = "PENDING";
        this.createdAt = System.currentTimeMillis();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getReporterId() { return reporterId; }
    public void setReporterId(String reporterId) { this.reporterId = reporterId; }

    public String getReportedId() { return reportedId; }
    public void setReportedId(String reportedId) { this.reportedId = reportedId; }

    public String getConversationId() { return conversationId; }
    public void setConversationId(String conversationId) { this.conversationId = conversationId; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public long getCreatedAt() { return createdAt; }
    public void setCreatedAt(long createdAt) { this.createdAt = createdAt; }
}
