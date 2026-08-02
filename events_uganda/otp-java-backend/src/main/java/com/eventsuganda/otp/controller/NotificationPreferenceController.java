package com.eventsuganda.otp.controller;

import com.eventsuganda.otp.dto.request.UpdateNotificationPreferenceRequest;
import com.eventsuganda.otp.dto.response.ApiResponse;
import com.eventsuganda.otp.dto.response.NotificationPreferenceResponse;
import com.eventsuganda.otp.service.NotificationPreferenceService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/notification-settings")
public class NotificationPreferenceController {

    private final NotificationPreferenceService preferenceService;

    public NotificationPreferenceController(NotificationPreferenceService preferenceService) {
        this.preferenceService = preferenceService;
    }

    @GetMapping
    public ResponseEntity<NotificationPreferenceResponse> get(Authentication auth) {
        String userId = (String) auth.getPrincipal();
        return ResponseEntity.ok(preferenceService.get(userId));
    }

    @PutMapping
    public ResponseEntity<NotificationPreferenceResponse> update(
            @Valid @RequestBody UpdateNotificationPreferenceRequest request,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        return ResponseEntity.ok(preferenceService.update(userId, request));
    }

    @PostMapping("/reset")
    public ResponseEntity<ApiResponse> reset(Authentication auth) {
        String userId = (String) auth.getPrincipal();
        NotificationPreferenceResponse response = preferenceService.reset(userId);
        return ResponseEntity.ok(ApiResponse.ok("Notification settings restored to defaults", response));
    }
}
