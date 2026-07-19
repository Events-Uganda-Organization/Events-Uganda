package com.eventsuganda.otp.dto.response;

import com.eventsuganda.otp.model.User;
import com.eventsuganda.otp.model.ReferralReward;

import java.util.List;

public class ReferralStatsResponse {

    private String referralCode;
    private int totalReferrals;
    private int approvedReferrals;
    private int totalRewards;
    private List<ReferralDetail> recentReferrals;

    public ReferralStatsResponse() {}

    public ReferralStatsResponse(String referralCode, int totalReferrals, int approvedReferrals, int totalRewards, List<ReferralDetail> recentReferrals) {
        this.referralCode = referralCode;
        this.totalReferrals = totalReferrals;
        this.approvedReferrals = approvedReferrals;
        this.totalRewards = totalRewards;
        this.recentReferrals = recentReferrals;
    }

    public String getReferralCode() { return referralCode; }
    public void setReferralCode(String referralCode) { this.referralCode = referralCode; }

    public int getTotalReferrals() { return totalReferrals; }
    public void setTotalReferrals(int totalReferrals) { this.totalReferrals = totalReferrals; }

    public int getApprovedReferrals() { return approvedReferrals; }
    public void setApprovedReferrals(int approvedReferrals) { this.approvedReferrals = approvedReferrals; }

    public int getTotalRewards() { return totalRewards; }
    public void setTotalRewards(int totalRewards) { this.totalRewards = totalRewards; }

    public List<ReferralDetail> getRecentReferrals() { return recentReferrals; }
    public void setRecentReferrals(List<ReferralDetail> recentReferrals) { this.recentReferrals = recentReferrals; }

    public static class ReferralDetail {
        private String referredUserName;
        private String rewardType;
        private int rewardAmount;
        private String status;
        private long createdAt;

        public ReferralDetail() {}

        public ReferralDetail(ReferralReward reward, String referredUserName) {
            this.referredUserName = referredUserName;
            this.rewardType = reward.getRewardType();
            this.rewardAmount = reward.getRewardAmount();
            this.status = reward.getStatus();
            this.createdAt = reward.getCreatedAt();
        }

        public String getReferredUserName() { return referredUserName; }
        public void setReferredUserName(String referredUserName) { this.referredUserName = referredUserName; }

        public String getRewardType() { return rewardType; }
        public void setRewardType(String rewardType) { this.rewardType = rewardType; }

        public int getRewardAmount() { return rewardAmount; }
        public void setRewardAmount(int rewardAmount) { this.rewardAmount = rewardAmount; }

        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }

        public long getCreatedAt() { return createdAt; }
        public void setCreatedAt(long createdAt) { this.createdAt = createdAt; }
    }
}
