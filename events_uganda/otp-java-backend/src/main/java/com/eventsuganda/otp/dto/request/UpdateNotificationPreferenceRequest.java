package com.eventsuganda.otp.dto.request;

import jakarta.validation.constraints.NotNull;

public class UpdateNotificationPreferenceRequest {

    @NotNull
    private Boolean pushEnabled;

    @NotNull
    private Boolean emailEnabled;

    @NotNull
    private Boolean smsEnabled;

    @NotNull
    private Boolean bookingUpdates;

    @NotNull
    private Boolean promotions;

    @NotNull
    private Boolean messages;

    @NotNull
    private Boolean reminders;

    @NotNull
    private Boolean soundEnabled;

    @NotNull
    private Boolean vibrationEnabled;

    public Boolean getPushEnabled() { return pushEnabled; }
    public void setPushEnabled(Boolean pushEnabled) { this.pushEnabled = pushEnabled; }

    public Boolean getEmailEnabled() { return emailEnabled; }
    public void setEmailEnabled(Boolean emailEnabled) { this.emailEnabled = emailEnabled; }

    public Boolean getSmsEnabled() { return smsEnabled; }
    public void setSmsEnabled(Boolean smsEnabled) { this.smsEnabled = smsEnabled; }

    public Boolean getBookingUpdates() { return bookingUpdates; }
    public void setBookingUpdates(Boolean bookingUpdates) { this.bookingUpdates = bookingUpdates; }

    public Boolean getPromotions() { return promotions; }
    public void setPromotions(Boolean promotions) { this.promotions = promotions; }

    public Boolean getMessages() { return messages; }
    public void setMessages(Boolean messages) { this.messages = messages; }

    public Boolean getReminders() { return reminders; }
    public void setReminders(Boolean reminders) { this.reminders = reminders; }

    public Boolean getSoundEnabled() { return soundEnabled; }
    public void setSoundEnabled(Boolean soundEnabled) { this.soundEnabled = soundEnabled; }

    public Boolean getVibrationEnabled() { return vibrationEnabled; }
    public void setVibrationEnabled(Boolean vibrationEnabled) { this.vibrationEnabled = vibrationEnabled; }
}
