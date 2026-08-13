package com.eventsuganda.otp.dto.request;

import jakarta.validation.constraints.NotBlank;

public class DisappearingModeRequest {

    @NotBlank(message = "Mode is required")
    private String mode;

    public String getMode() { return mode; }
    public void setMode(String mode) { this.mode = mode; }
}
