package com.eventsuganda.otp.model;

import jakarta.persistence.*;

@Entity
@Table(name = "user_blocks")
@IdClass(UserBlockId.class)
public class UserBlock {

    @Id
    @Column(nullable = false)
    private String blockerId;

    @Id
    @Column(nullable = false)
    private String blockedId;

    @Column(nullable = false)
    private long createdAt;

    public UserBlock() {}

    public UserBlock(String blockerId, String blockedId) {
        this.blockerId = blockerId;
        this.blockedId = blockedId;
        this.createdAt = System.currentTimeMillis();
    }

    public String getBlockerId() { return blockerId; }
    public void setBlockerId(String blockerId) { this.blockerId = blockerId; }

    public String getBlockedId() { return blockedId; }
    public void setBlockedId(String blockedId) { this.blockedId = blockedId; }

    public long getCreatedAt() { return createdAt; }
    public void setCreatedAt(long createdAt) { this.createdAt = createdAt; }
}
