package com.eventsuganda.otp.dto.response;

import com.eventsuganda.otp.model.Conversation;

public class ConversationResponse {

    private String id;
    private String participantIds;
    private String lastMessage;
    private String lastMessageSenderId;
    private Long lastMessageAt;
    private long createdAt;
    private long updatedAt;
    private long unreadCount;

    public ConversationResponse() {}

    public ConversationResponse(Conversation conversation, long unreadCount) {
        this.id = conversation.getId();
        this.participantIds = conversation.getParticipantIds();
        this.lastMessage = conversation.getLastMessage();
        this.lastMessageSenderId = conversation.getLastMessageSenderId();
        this.lastMessageAt = conversation.getLastMessageAt();
        this.createdAt = conversation.getCreatedAt();
        this.updatedAt = conversation.getUpdatedAt();
        this.unreadCount = unreadCount;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getParticipantIds() { return participantIds; }
    public void setParticipantIds(String participantIds) { this.participantIds = participantIds; }

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

    public long getUnreadCount() { return unreadCount; }
    public void setUnreadCount(long unreadCount) { this.unreadCount = unreadCount; }
}
