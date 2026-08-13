package com.eventsuganda.otp.model;

import jakarta.persistence.*;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "conversations")
public class Conversation {

    @Id
    private String id;

    @Column(nullable = false)
    private String participantIds;

    private String lastMessage;

    private String lastMessageSenderId;

    private Long lastMessageAt;

    @Column(nullable = false)
    private long createdAt;

    @Column(nullable = false)
    private long updatedAt;

    @Column(nullable = false)
    private String disappearingMode = "OFF";

    public Conversation() {}

    public Conversation(String id, Set<String> participantIds) {
        this.id = id;
        this.participantIds = String.join(",", participantIds);
        this.createdAt = System.currentTimeMillis();
        this.updatedAt = this.createdAt;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getParticipantIds() { return participantIds; }
    public void setParticipantIds(String participantIds) { this.participantIds = participantIds; }

    public Set<String> getParticipantIdSet() {
        return new HashSet<>(Arrays.asList(participantIds.split(",")));
    }

    public String getLastMessage() { return lastMessage; }
    public void setLastMessage(String lastMessage) { this.lastMessage = lastMessage; }

    public String getLastMessageSenderId() { return lastMessageSenderId; }
    public void setLastMessageSenderId(String lastMessageSenderId) { this.lastMessageSenderId = lastMessageSenderId; }

    public Long getLastMessageAt() { return lastMessageAt; }
    public void setLastMessageAt(Long lastMessageAt) { this.lastMessageAt = lastMessageAt; }

    public long getCreatedAt() { return createdAt; }
    public void setCreatedAt(long createdAt) { this.createdAt = createdAt; }

    public long getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(long updatedAt) { this.updatedAt = updatedAt; }

    public String getDisappearingMode() { return disappearingMode; }
    public void setDisappearingMode(String disappearingMode) { this.disappearingMode = disappearingMode; }
}
