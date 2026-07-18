package com.eventsuganda.otp.dto.response;

import com.eventsuganda.otp.model.Message;

public class MessageResponse {

    private String id;
    private String conversationId;
    private String senderId;
    private String text;
    private String imageUrl;
    private long createdAt;
    private Long readAt;
    private boolean isMine;

    public MessageResponse() {}

    public MessageResponse(Message message, String currentUserId) {
        this.id = message.getId();
        this.conversationId = message.getConversationId();
        this.senderId = message.getSenderId();
        this.text = message.getText();
        this.imageUrl = message.getImageUrl();
        this.createdAt = message.getCreatedAt();
        this.readAt = message.getReadAt();
        this.isMine = message.getSenderId().equals(currentUserId);
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getConversationId() { return conversationId; }
    public void setConversationId(String conversationId) { this.conversationId = conversationId; }

    public String getSenderId() { return senderId; }
    public void setSenderId(String senderId) { this.senderId = senderId; }

    public String getText() { return text; }
    public void setText(String text) { this.text = text; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public long getCreatedAt() { return createdAt; }
    public void setCreatedAt(long createdAt) { this.createdAt = createdAt; }

    public Long getReadAt() { return readAt; }
    public void setReadAt(Long readAt) { this.readAt = readAt; }

    public boolean isMine() { return isMine; }
    public void setMine(boolean mine) { isMine = mine; }
}
