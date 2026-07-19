package com.eventsuganda.otp.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;

import java.util.Set;

public class CreateConversationRequest {

    @NotEmpty(message = "At least one participant is required")
    private Set<String> participantIds;

    private String initialMessage;

    public Set<String> getParticipantIds() { return participantIds; }
    public void setParticipantIds(Set<String> participantIds) { this.participantIds = participantIds; }

    public String getInitialMessage() { return initialMessage; }
    public void setInitialMessage(String initialMessage) { this.initialMessage = initialMessage; }
}
