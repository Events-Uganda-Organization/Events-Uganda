package com.eventsuganda.otp.repository;

import com.eventsuganda.otp.model.ReferralReward;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ReferralRewardRepository extends JpaRepository<ReferralReward, String> {

    List<ReferralReward> findByUserIdOrderByCreatedAtDesc(String userId);

    Optional<ReferralReward> findByUserIdAndReferredUserId(String userId, String referredUserId);

    @Query("SELECT COALESCE(SUM(r.rewardAmount), 0) FROM ReferralReward r WHERE r.userId = :userId AND r.status = 'APPROVED'")
    int getTotalRewardsByUserId(@Param("userId") String userId);

    @Query("SELECT COUNT(r) FROM ReferralReward r WHERE r.userId = :userId")
    int getReferralCountByUserId(@Param("userId") String userId);

    @Query("SELECT COUNT(r) FROM ReferralReward r WHERE r.userId = :userId AND r.status = 'APPROVED'")
    int getApprovedReferralCountByUserId(@Param("userId") String userId);
}
