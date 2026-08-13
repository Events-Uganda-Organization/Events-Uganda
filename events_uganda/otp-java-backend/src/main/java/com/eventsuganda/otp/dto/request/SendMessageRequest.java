package com.eventsuganda.otp.dto.request;

import jakarta.validation.constraints.Size;

public class SendMessageRequest {

    @Size(max = 5000, message = "Message text is too long")
    private String text;

    public String getText() { return text; }
    public void setText(String text) { this.text = text; }
}
