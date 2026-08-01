package com.eventsuganda.otp.dto.request;

import jakarta.validation.constraints.NotBlank;

public class ChatMessageRequest {

    @NotBlank(message = "Conversation id is required")
    private String conversationId;

    @NotBlank(message = "Message text is required")
    private String text;

    public String getConversationId() { return conversationId; }
    public void setConversationId(String conversationId) { this.conversationId = conversationId; }

    public String getText() { return text; }
    public void setText(String text) { this.text = text; }
}
