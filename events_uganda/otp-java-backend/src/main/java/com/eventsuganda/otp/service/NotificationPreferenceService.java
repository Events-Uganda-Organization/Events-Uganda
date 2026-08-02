package com.eventsuganda.otp.service;

import com.eventsuganda.otp.dto.request.UpdateNotificationPreferenceRequest;
import com.eventsuganda.otp.dto.response.NotificationPreferenceResponse;
import com.eventsuganda.otp.model.NotificationPreference;
import com.eventsuganda.otp.repository.NotificationPreferenceRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NotificationPreferenceService {

    private final NotificationPreferenceRepository preferenceRepository;

    public NotificationPreferenceService(NotificationPreferenceRepository preferenceRepository) {
        this.preferenceRepository = preferenceRepository;
    }

    public NotificationPreferenceResponse get(String userId) {
        return new NotificationPreferenceResponse(preference(userId));
    }

    @Transactional
    public NotificationPreferenceResponse update(String userId, UpdateNotificationPreferenceRequest request) {
        NotificationPreference preference = preference(userId);
        preference.setPushEnabled(request.getPushEnabled());
        preference.setEmailEnabled(request.getEmailEnabled());
        preference.setSmsEnabled(request.getSmsEnabled());
        preference.setBookingUpdates(request.getBookingUpdates());
        preference.setPromotions(request.getPromotions());
        preference.setMessages(request.getMessages());
        preference.setReminders(request.getReminders());
        preference.setSoundEnabled(request.getSoundEnabled());
        preference.setVibrationEnabled(request.getVibrationEnabled());
        preferenceRepository.save(preference);
        return new NotificationPreferenceResponse(preference);
    }

    @Transactional
    public NotificationPreferenceResponse reset(String userId) {
        NotificationPreference preference = NotificationPreference.defaults(userId);
        preferenceRepository.save(preference);
        return new NotificationPreferenceResponse(preference);
    }

    private NotificationPreference preference(String userId) {
        return preferenceRepository.findById(userId)
            .orElseGet(() -> preferenceRepository.save(NotificationPreference.defaults(userId)));
    }
}
