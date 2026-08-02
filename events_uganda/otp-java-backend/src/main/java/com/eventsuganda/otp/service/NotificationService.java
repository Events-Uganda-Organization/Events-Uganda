package com.eventsuganda.otp.service;

import com.eventsuganda.otp.dto.request.CreateNotificationRequest;
import com.eventsuganda.otp.dto.response.NotificationResponse;
import com.eventsuganda.otp.exception.OtpException;
import com.eventsuganda.otp.model.Notification;
import com.eventsuganda.otp.repository.NotificationRepository;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class NotificationService {

    private static final String NOTIFICATION_QUEUE = "/queue/notifications";

    private final NotificationRepository notificationRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public NotificationService(NotificationRepository notificationRepository,
                               SimpMessagingTemplate messagingTemplate) {
        this.notificationRepository = notificationRepository;
        this.messagingTemplate = messagingTemplate;
    }

    public List<NotificationResponse> listActive(String userId) {
        return notificationRepository.findByUserIdAndArchivedAtIsNullOrderByCreatedAtDesc(userId)
            .stream()
            .map(NotificationResponse::new)
            .collect(Collectors.toList());
    }

    public List<NotificationResponse> listArchived(String userId) {
        return notificationRepository.findByUserIdAndArchivedAtIsNotNullOrderByCreatedAtDesc(userId)
            .stream()
            .map(NotificationResponse::new)
            .collect(Collectors.toList());
    }

    public long unreadCount(String userId) {
        return notificationRepository.countByUserIdAndArchivedAtIsNullAndReadAtIsNull(userId);
    }

    @Transactional
    public NotificationResponse create(CreateNotificationRequest request) {
        String id = UUID.randomUUID().toString();
        String body = request.getBody() == null ? null : request.getBody().trim();
        String category = request.getCategory() == null ? null : request.getCategory().trim().toUpperCase();
        Notification notification = new Notification(
            id,
            request.getUserId(),
            request.getType().trim(),
            request.getTitle().trim(),
            body,
            category);
        notificationRepository.save(notification);

        NotificationResponse response = new NotificationResponse(notification);
        messagingTemplate.convertAndSendToUser(request.getUserId(), NOTIFICATION_QUEUE, response);
        return response;
    }

    @Transactional
    public NotificationResponse markRead(String userId, String id) {
        Notification notification = owned(userId, id);
        if (notification.getReadAt() == null) {
            notification.setReadAt(System.currentTimeMillis());
            notificationRepository.save(notification);
        }
        return new NotificationResponse(notification);
    }

    @Transactional
    public NotificationResponse markUnread(String userId, String id) {
        Notification notification = owned(userId, id);
        if (notification.getReadAt() != null) {
            notification.setReadAt(null);
            notificationRepository.save(notification);
        }
        return new NotificationResponse(notification);
    }

    @Transactional
    public int markAllRead(String userId) {
        return notificationRepository.markAllRead(userId, System.currentTimeMillis());
    }

    @Transactional
    public NotificationResponse archive(String userId, String id) {
        Notification notification = owned(userId, id);
        if (notification.getArchivedAt() == null) {
            notification.setArchivedAt(System.currentTimeMillis());
            notificationRepository.save(notification);
        }
        return new NotificationResponse(notification);
    }

    @Transactional
    public NotificationResponse restore(String userId, String id) {
        Notification notification = owned(userId, id);
        if (notification.getArchivedAt() != null) {
            notification.setArchivedAt(null);
            notificationRepository.save(notification);
        }
        return new NotificationResponse(notification);
    }

    @Transactional
    public void delete(String userId, String id) {
        Notification notification = owned(userId, id);
        notificationRepository.delete(notification);
    }

    @Transactional
    public int deleteAllRead(String userId) {
        return notificationRepository.deleteAllRead(userId);
    }

    private Notification owned(String userId, String id) {
        Notification notification = notificationRepository.findById(id)
            .orElseThrow(() -> new OtpException("Notification not found"));
        if (!notification.getUserId().equals(userId)) {
            throw new OtpException("Access denied");
        }
        return notification;
    }
}
