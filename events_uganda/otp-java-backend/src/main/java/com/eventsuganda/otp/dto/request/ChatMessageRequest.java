package com.eventsuganda.otp.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class ChatMessageRequest {

    @NotBlank(message = "Conversation id is required")
    private String conversationId;

    @Size(max = 5000, message = "Message text is too long")
    private String text;

    public String getConversationId() { return conversationId; }
    public void setConversationId(String conversationId) { this.conversationId = conversationId; }

    public String getText() { return text; }
    public void setText(String text) { this.text = text; }
}
