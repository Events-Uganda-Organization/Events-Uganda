package com.eventsuganda.otp.service;

import com.eventsuganda.otp.dto.response.ReferralStatsResponse;
import com.eventsuganda.otp.exception.OtpException;
import com.eventsuganda.otp.model.ReferralReward;
import com.eventsuganda.otp.model.User;
import com.eventsuganda.otp.repository.ReferralRewardRepository;
import com.eventsuganda.otp.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ReferralRewardService {

    private final ReferralRewardRepository referralRewardRepository;
    private final UserRepository userRepository;

    public ReferralRewardService(ReferralRewardRepository referralRewardRepository, UserRepository userRepository) {
        this.referralRewardRepository = referralRewardRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public ReferralReward createReferralReward(String userId, String referredUserId) {
        Optional<ReferralReward> existing = referralRewardRepository.findByUserIdAndReferredUserId(userId, referredUserId);
        if (existing.isPresent()) {
            return existing.get();
        }

        ReferralReward reward = new ReferralReward(
            UUID.randomUUID().toString(),
            userId,
            referredUserId,
            "POINTS",
            100
        );
        return referralRewardRepository.save(reward);
    }

    @Transactional
    public ReferralReward approveReward(String rewardId, String userId) {
        ReferralReward reward = referralRewardRepository.findById(rewardId)
            .orElseThrow(() -> new OtpException("Reward not found"));

        if (!reward.getUserId().equals(userId)) {
            throw new OtpException("Access denied");
        }

        reward.setStatus("APPROVED");
        return referralRewardRepository.save(reward);
    }

    public ReferralStatsResponse getReferralStats(String userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new OtpException("User not found"));

        int totalReferrals = referralRewardRepository.getReferralCountByUserId(userId);
        int approvedReferrals = referralRewardRepository.getApprovedReferralCountByUserId(userId);
        int totalRewards = referralRewardRepository.getTotalRewardsByUserId(userId);

        List<ReferralReward> rewards = referralRewardRepository.findByUserIdOrderByCreatedAtDesc(userId);

        List<ReferralStatsResponse.ReferralDetail> details = rewards.stream()
            .map(r -> {
                String referredName = userRepository.findById(r.getReferredUserId())
                    .map(User::getFullName)
                    .orElse("Unknown");
                return new ReferralStatsResponse.ReferralDetail(r, referredName);
            })
            .collect(Collectors.toList());

        return new ReferralStatsResponse(
            user.getReferralCode(),
            totalReferrals,
            approvedReferrals,
            totalRewards,
            details
        );
    }
}
