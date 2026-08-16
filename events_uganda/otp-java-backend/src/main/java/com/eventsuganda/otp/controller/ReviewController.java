package com.eventsuganda.otp.controller;

import com.eventsuganda.otp.dto.request.ReviewRequest;
import com.eventsuganda.otp.dto.response.ApiResponse;
import com.eventsuganda.otp.dto.response.ReviewResponse;
import com.eventsuganda.otp.dto.response.ReviewSummaryResponse;
import com.eventsuganda.otp.service.ReviewService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/reviews")
public class ReviewController {

    private final ReviewService reviewService;

    public ReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }

    @GetMapping("/service/{serviceId}")
    public ResponseEntity<List<ReviewResponse>> list(@PathVariable String serviceId) {
        return ResponseEntity.ok(reviewService.list(serviceId));
    }

    @GetMapping("/service/{serviceId}/summary")
    public ResponseEntity<ReviewSummaryResponse> summary(@PathVariable String serviceId) {
        return ResponseEntity.ok(reviewService.summary(serviceId));
    }

    @PostMapping("/service/{serviceId}")
    public ResponseEntity<ReviewResponse> submit(
            @PathVariable String serviceId,
            @Valid @RequestBody ReviewRequest request,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        return ResponseEntity.ok(reviewService.submit(userId, serviceId, request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ReviewResponse> update(
            @PathVariable String id,
            @Valid @RequestBody ReviewRequest request,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        return ResponseEntity.ok(reviewService.update(userId, id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse> delete(
            @PathVariable String id,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        reviewService.delete(userId, id);
        return ResponseEntity.ok(ApiResponse.ok("Review deleted"));
    }
}
