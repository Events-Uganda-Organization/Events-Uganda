package com.eventsuganda.otp.model;

import jakarta.persistence.*;

@Entity
@Table(name = "message_media")
public class MessageMedia {

    @Id
    private String id;

    @Column(nullable = false)
    private String messageId;

    @Column(nullable = false)
    private String mediaType;

    @Column(nullable = false)
    private String mimeType;

    @Column(nullable = false, columnDefinition = "bytea")
    private byte[] data;

    private Long durationMs;

    @Column(nullable = false)
    private long createdAt;

    public MessageMedia() {}

    public MessageMedia(String id, String messageId, String mediaType, String mimeType,
                        byte[] data, Long durationMs) {
        this.id = id;
        this.messageId = messageId;
        this.mediaType = mediaType;
        this.mimeType = mimeType;
        this.data = data;
        this.durationMs = durationMs;
        this.createdAt = System.currentTimeMillis();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getMessageId() { return messageId; }
    public void setMessageId(String messageId) { this.messageId = messageId; }

    public String getMediaType() { return mediaType; }
    public void setMediaType(String mediaType) { this.mediaType = mediaType; }

    public String getMimeType() { return mimeType; }
    public void setMimeType(String mimeType) { this.mimeType = mimeType; }

    public byte[] getData() { return data; }
    public void setData(byte[] data) { this.data = data; }

    public Long getDurationMs() { return durationMs; }
    public void setDurationMs(Long durationMs) { this.durationMs = durationMs; }

    public long getCreatedAt() { return createdAt; }
    public void setCreatedAt(long createdAt) { this.createdAt = createdAt; }
}
