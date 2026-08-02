package com.eventsuganda.otp.dto.response;

import java.util.List;

public class ChatSearchResponse {

    private List<ConversationResponse> conversations;
    private List<MessageResponse> messages;

    public ChatSearchResponse() {}

    public ChatSearchResponse(List<ConversationResponse> conversations, List<MessageResponse> messages) {
        this.conversations = conversations;
        this.messages = messages;
    }

    public List<ConversationResponse> getConversations() { return conversations; }
    public void setConversations(List<ConversationResponse> conversations) { this.conversations = conversations; }

    public List<MessageResponse> getMessages() { return messages; }
    public void setMessages(List<MessageResponse> messages) { this.messages = messages; }
}
