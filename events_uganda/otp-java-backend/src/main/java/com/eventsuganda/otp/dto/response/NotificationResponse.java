package com.eventsuganda.otp.dto.response;

import com.eventsuganda.otp.model.Notification;

public class NotificationResponse {

    private String id;
    private String type;
    private String title;
    private String body;
    private String category;
    private long createdAt;
    private Long readAt;
    private Long archivedAt;
    private boolean isRead;
    private boolean isArchived;

    public NotificationResponse() {}

    public NotificationResponse(Notification notification) {
        this.id = notification.getId();
        this.type = notification.getType();
        this.title = notification.getTitle();
        this.body = notification.getBody();
        this.category = notification.getCategory();
        this.createdAt = notification.getCreatedAt();
        this.readAt = notification.getReadAt();
        this.archivedAt = notification.getArchivedAt();
        this.isRead = notification.getReadAt() != null;
        this.isArchived = notification.getArchivedAt() != null;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getBody() { return body; }
    public void setBody(String body) { this.body = body; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public long getCreatedAt() { return createdAt; }
    public void setCreatedAt(long createdAt) { this.createdAt = createdAt; }

    public Long getReadAt() { return readAt; }
    public void setReadAt(Long readAt) { this.readAt = readAt; }

    public Long getArchivedAt() { return archivedAt; }
    public void setArchivedAt(Long archivedAt) { this.archivedAt = archivedAt; }

    public boolean isRead() { return isRead; }
    public void setRead(boolean read) { isRead = read; }

    public boolean isArchived() { return isArchived; }
    public void setArchived(boolean archived) { isArchived = archived; }
}
