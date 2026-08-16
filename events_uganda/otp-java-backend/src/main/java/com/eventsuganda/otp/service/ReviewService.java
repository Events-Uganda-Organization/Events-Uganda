package com.eventsuganda.otp.service;

import com.eventsuganda.otp.dto.request.ReviewRequest;
import com.eventsuganda.otp.dto.response.ReviewResponse;
import com.eventsuganda.otp.dto.response.ReviewSummaryResponse;
import com.eventsuganda.otp.exception.OtpException;
import com.eventsuganda.otp.model.Review;
import com.eventsuganda.otp.model.User;
import com.eventsuganda.otp.repository.ReviewRepository;
import com.eventsuganda.otp.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class ReviewService {

    private static final DateTimeFormatter DATE_FORMAT =
        DateTimeFormatter.ofPattern("dd/MM/yyyy").withZone(ZoneId.systemDefault());

    private final ReviewRepository reviewRepository;
    private final UserRepository userRepository;

    public ReviewService(ReviewRepository reviewRepository, UserRepository userRepository) {
        this.reviewRepository = reviewRepository;
        this.userRepository = userRepository;
    }

    public List<ReviewResponse> list(String serviceId) {
        return reviewRepository.findByServiceIdOrderByCreatedAtDesc(serviceId).stream()
            .map(this::toResponse)
            .toList();
    }

    public ReviewSummaryResponse summary(String serviceId) {
        long total = reviewRepository.countByServiceId(serviceId);
        long[] starCounts = new long[6];
        long sum = 0;
        for (Object[] row : reviewRepository.countByRating(serviceId)) {
            int rating = ((Number) row[0]).intValue();
            long count = ((Number) row[1]).longValue();
            if (rating >= 1 && rating <= 5) {
                starCounts[rating] = count;
                sum += (long) rating * count;
            }
        }
        double avg = total == 0 ? 0.0 : (double) sum / total;
        return new ReviewSummaryResponse(Math.round(avg * 10.0) / 10.0, total, starCounts);
    }

    /** Creates the caller's review for a service, or updates it if it already exists. */
    public ReviewResponse submit(String userId, String serviceId, ReviewRequest request) {
        validateRating(request.getRating());
        Review review = reviewRepository.findByServiceIdAndUserId(serviceId, userId)
            .orElseGet(() -> new Review(
                UUID.randomUUID().toString(), serviceId, userId,
                request.getRating(), request.getReviewText()));
        review.setRating(request.getRating());
        review.setReviewText(request.getReviewText());
        review.setUpdatedAt(System.currentTimeMillis());
        return toResponse(reviewRepository.save(review));
    }

    public ReviewResponse update(String userId, String reviewId, ReviewRequest request) {
        validateRating(request.getRating());
        Review review = owned(reviewId, userId);
        review.setRating(request.getRating());
        review.setReviewText(request.getReviewText());
        review.setUpdatedAt(System.currentTimeMillis());
        return toResponse(reviewRepository.save(review));
    }

    public void delete(String userId, String reviewId) {
        Review review = owned(reviewId, userId);
        reviewRepository.delete(review);
    }

    private Review owned(String reviewId, String userId) {
        Optional<Review> existing = reviewRepository.findById(reviewId);
        if (existing.isEmpty()) {
            throw new OtpException("Review not found");
        }
        Review review = existing.get();
        if (!review.getUserId().equals(userId)) {
            throw new OtpException("You can only modify your own review");
        }
        return review;
    }

    private void validateRating(int rating) {
        if (rating < 1 || rating > 5) {
            throw new OtpException("Rating must be between 1 and 5");
        }
    }

    private ReviewResponse toResponse(Review review) {
        Optional<User> author = userRepository.findById(review.getUserId());
        String name = author.map(User::getFullName).orElse("User");
        String photo = author.map(User::getPhotoUrl).orElse(null);
        String date = DATE_FORMAT.format(Instant.ofEpochMilli(review.getCreatedAt()));
        return new ReviewResponse(
            review.getId(), name, photo, review.getReviewText(), date, review.getRating());
    }
}
