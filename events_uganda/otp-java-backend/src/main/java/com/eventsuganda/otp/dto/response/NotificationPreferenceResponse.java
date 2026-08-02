package com.eventsuganda.otp.dto.response;

import com.eventsuganda.otp.model.NotificationPreference;

public class NotificationPreferenceResponse {

    private String userId;
    private boolean pushEnabled;
    private boolean emailEnabled;
    private boolean smsEnabled;
    private boolean bookingUpdates;
    private boolean promotions;
    private boolean messages;
    private boolean reminders;
    private boolean soundEnabled;
    private boolean vibrationEnabled;

    public NotificationPreferenceResponse() {}

    public NotificationPreferenceResponse(NotificationPreference preference) {
        this.userId = preference.getUserId();
        this.pushEnabled = preference.isPushEnabled();
        this.emailEnabled = preference.isEmailEnabled();
        this.smsEnabled = preference.isSmsEnabled();
        this.bookingUpdates = preference.isBookingUpdates();
        this.promotions = preference.isPromotions();
        this.messages = preference.isMessages();
        this.reminders = preference.isReminders();
        this.soundEnabled = preference.isSoundEnabled();
        this.vibrationEnabled = preference.isVibrationEnabled();
    }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public boolean isPushEnabled() { return pushEnabled; }
    public void setPushEnabled(boolean pushEnabled) { this.pushEnabled = pushEnabled; }

    public boolean isEmailEnabled() { return emailEnabled; }
    public void setEmailEnabled(boolean emailEnabled) { this.emailEnabled = emailEnabled; }

    public boolean isSmsEnabled() { return smsEnabled; }
    public void setSmsEnabled(boolean smsEnabled) { this.smsEnabled = smsEnabled; }

    public boolean isBookingUpdates() { return bookingUpdates; }
    public void setBookingUpdates(boolean bookingUpdates) { this.bookingUpdates = bookingUpdates; }

    public boolean isPromotions() { return promotions; }
    public void setPromotions(boolean promotions) { this.promotions = promotions; }

    public boolean isMessages() { return messages; }
    public void setMessages(boolean messages) { this.messages = messages; }

    public boolean isReminders() { return reminders; }
    public void setReminders(boolean reminders) { this.reminders = reminders; }

    public boolean isSoundEnabled() { return soundEnabled; }
    public void setSoundEnabled(boolean soundEnabled) { this.soundEnabled = soundEnabled; }

    public boolean isVibrationEnabled() { return vibrationEnabled; }
    public void setVibrationEnabled(boolean vibrationEnabled) { this.vibrationEnabled = vibrationEnabled; }
}
