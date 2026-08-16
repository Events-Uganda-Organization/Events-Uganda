package com.eventsuganda.otp.repository;

import com.eventsuganda.otp.model.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ReviewRepository extends JpaRepository<Review, String> {

    List<Review> findByServiceIdOrderByCreatedAtDesc(String serviceId);

    Optional<Review> findByServiceIdAndUserId(String serviceId, String userId);

    long countByServiceId(String serviceId);

    @Query("select r.rating, count(r) from Review r where r.serviceId = :serviceId group by r.rating")
    List<Object[]> countByRating(@Param("serviceId") String serviceId);
}
