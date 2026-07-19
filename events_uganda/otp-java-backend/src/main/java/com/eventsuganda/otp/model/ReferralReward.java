package com.eventsuganda.otp.model;

import jakarta.persistence.*;

@Entity
@Table(name = "referral_rewards", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"user_id", "referred_user_id"})
})
public class ReferralReward {

    @Id
    private String id;

    @Column(nullable = false)
    private String userId;

    @Column(nullable = false)
    private String referredUserId;

    @Column(nullable = false)
    private String rewardType;

    @Column(nullable = false)
    private int rewardAmount;

    @Column(nullable = false)
    private String status;

    @Column(nullable = false)
    private long createdAt;

    public ReferralReward() {}

    public ReferralReward(String id, String userId, String referredUserId, String rewardType, int rewardAmount) {
        this.id = id;
        this.userId = userId;
        this.referredUserId = referredUserId;
        this.rewardType = rewardType;
        this.rewardAmount = rewardAmount;
        this.status = "PENDING";
        this.createdAt = System.currentTimeMillis();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getReferredUserId() { return referredUserId; }
    public void setReferredUserId(String referredUserId) { this.referredUserId = referredUserId; }

    public String getRewardType() { return rewardType; }
    public void setRewardType(String rewardType) { this.rewardType = rewardType; }

    public int getRewardAmount() { return rewardAmount; }
    public void setRewardAmount(int rewardAmount) { this.rewardAmount = rewardAmount; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public long getCreatedAt() { return createdAt; }
    public void setCreatedAt(long createdAt) { this.createdAt = createdAt; }
}
