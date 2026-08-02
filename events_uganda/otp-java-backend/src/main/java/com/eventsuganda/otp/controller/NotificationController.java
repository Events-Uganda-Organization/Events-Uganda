package com.eventsuganda.otp.controller;

import com.eventsuganda.otp.dto.request.CreateNotificationRequest;
import com.eventsuganda.otp.dto.response.ApiResponse;
import com.eventsuganda.otp.dto.response.NotificationResponse;
import com.eventsuganda.otp.service.NotificationService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping
    public ResponseEntity<List<NotificationResponse>> list(
            @RequestParam(defaultValue = "false") boolean archived,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        List<NotificationResponse> notifications = archived
            ? notificationService.listArchived(userId)
            : notificationService.listActive(userId);
        return ResponseEntity.ok(notifications);
    }

    @GetMapping("/unread-count")
    public ResponseEntity<Long> unreadCount(Authentication auth) {
        String userId = (String) auth.getPrincipal();
        return ResponseEntity.ok(notificationService.unreadCount(userId));
    }

    @PostMapping
    public ResponseEntity<NotificationResponse> create(
            @Valid @RequestBody CreateNotificationRequest request,
            Authentication auth) {
        @SuppressWarnings("unused")
        String callerId = (String) auth.getPrincipal();
        return ResponseEntity.ok(notificationService.create(request));
    }

    @PostMapping("/read-all")
    public ResponseEntity<ApiResponse> markAllRead(Authentication auth) {
        String userId = (String) auth.getPrincipal();
        int updated = notificationService.markAllRead(userId);
        return ResponseEntity.ok(ApiResponse.ok(updated + " notifications marked as read"));
    }

    @PostMapping("/{id}/read")
    public ResponseEntity<NotificationResponse> markRead(
            @PathVariable String id,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        return ResponseEntity.ok(notificationService.markRead(userId, id));
    }

    @PostMapping("/{id}/unread")
    public ResponseEntity<NotificationResponse> markUnread(
            @PathVariable String id,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        return ResponseEntity.ok(notificationService.markUnread(userId, id));
    }

    @PostMapping("/{id}/archive")
    public ResponseEntity<NotificationResponse> archive(
            @PathVariable String id,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        return ResponseEntity.ok(notificationService.archive(userId, id));
    }

    @PostMapping("/{id}/restore")
    public ResponseEntity<NotificationResponse> restore(
            @PathVariable String id,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        return ResponseEntity.ok(notificationService.restore(userId, id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse> delete(
            @PathVariable String id,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        notificationService.delete(userId, id);
        return ResponseEntity.ok(ApiResponse.ok("Notification deleted"));
    }

    @DeleteMapping("/read")
    public ResponseEntity<ApiResponse> deleteAllRead(Authentication auth) {
        String userId = (String) auth.getPrincipal();
        int deleted = notificationService.deleteAllRead(userId);
        return ResponseEntity.ok(ApiResponse.ok(deleted + " read notifications deleted"));
    }
}
