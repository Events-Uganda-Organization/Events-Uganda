package com.eventsuganda.otp.dto.request;

import jakarta.validation.constraints.NotBlank;

public class SendMessageRequest {

    @NotBlank(message = "Message text is required")
    private String text;

    public String getText() { return text; }
    public void setText(String text) { this.text = text; }
}
