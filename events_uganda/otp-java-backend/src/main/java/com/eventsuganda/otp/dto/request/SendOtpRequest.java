package com.eventsuganda.otp.dto.request;

import jakarta.validation.constraints.AssertTrue;

public class SendOtpRequest {

    private String email;
    private String phone;

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    @AssertTrue(message = "Either email or phone must be provided")
    public boolean isValid() {
        return (email != null && !email.isBlank()) || (phone != null && !phone.isBlank());
    }
}
