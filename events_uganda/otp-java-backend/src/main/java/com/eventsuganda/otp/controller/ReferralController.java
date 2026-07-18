package com.eventsuganda.otp.controller;

import com.eventsuganda.otp.dto.response.ApiResponse;
import com.eventsuganda.otp.dto.response.ReferralStatsResponse;
import com.eventsuganda.otp.service.ReferralRewardService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/referral")
public class ReferralController {

    private final ReferralRewardService referralRewardService;

    public ReferralController(ReferralRewardService referralRewardService) {
        this.referralRewardService = referralRewardService;
    }

    @GetMapping("/stats")
    public ResponseEntity<ReferralStatsResponse> getReferralStats(Authentication auth) {
        String userId = (String) auth.getPrincipal();
        return ResponseEntity.ok(referralRewardService.getReferralStats(userId));
    }

    @PostMapping("/rewards/{rewardId}/approve")
    public ResponseEntity<ApiResponse> approveReward(
            @PathVariable String rewardId,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        referralRewardService.approveReward(rewardId, userId);
        return ResponseEntity.ok(ApiResponse.ok("Reward approved"));
    }
}
