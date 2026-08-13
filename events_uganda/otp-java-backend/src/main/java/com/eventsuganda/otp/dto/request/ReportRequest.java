package com.eventsuganda.otp.dto.request;

import jakarta.validation.constraints.Size;

public class ReportRequest {

    @Size(max = 500, message = "Reason is too long")
    private String reason;

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
}
