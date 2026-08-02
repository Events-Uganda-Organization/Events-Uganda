package com.eventsuganda.otp.dto.request;

import jakarta.validation.constraints.NotBlank;

public class CreateNotificationRequest {

    @NotBlank(message = "Notification type is required")
    private String type;

    @NotBlank(message = "Notification title is required")
    private String title;

    private String body;

    private String category;

    @NotBlank(message = "Recipient userId is required")
    private String userId;

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getBody() { return body; }
    public void setBody(String body) { this.body = body; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
}
