package com.eventsuganda.otp.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "notification_preferences")
public class NotificationPreference {

    @Id
    private String userId;

    @Column(nullable = false)
    private boolean pushEnabled;

    @Column(nullable = false)
    private boolean emailEnabled;

    @Column(nullable = false)
    private boolean smsEnabled;

    @Column(nullable = false)
    private boolean bookingUpdates;

    @Column(nullable = false)
    private boolean promotions;

    @Column(nullable = false)
    private boolean messages;

    @Column(nullable = false)
    private boolean reminders;

    @Column(nullable = false)
    private boolean soundEnabled;

    @Column(nullable = false)
    private boolean vibrationEnabled;

    public NotificationPreference() {}

    public NotificationPreference(String userId, boolean pushEnabled, boolean emailEnabled,
                                  boolean smsEnabled, boolean bookingUpdates, boolean promotions,
                                  boolean messages, boolean reminders, boolean soundEnabled,
                                  boolean vibrationEnabled) {
        this.userId = userId;
        this.pushEnabled = pushEnabled;
        this.emailEnabled = emailEnabled;
        this.smsEnabled = smsEnabled;
        this.bookingUpdates = bookingUpdates;
        this.promotions = promotions;
        this.messages = messages;
        this.reminders = reminders;
        this.soundEnabled = soundEnabled;
        this.vibrationEnabled = vibrationEnabled;
    }

    public static NotificationPreference defaults(String userId) {
        return new NotificationPreference(
            userId,
            true,  // pushEnabled
            true,  // emailEnabled
            false, // smsEnabled
            true,  // bookingUpdates
            false, // promotions
            true,  // messages
            true,  // reminders
            true,  // soundEnabled
            true   // vibrationEnabled
        );
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
