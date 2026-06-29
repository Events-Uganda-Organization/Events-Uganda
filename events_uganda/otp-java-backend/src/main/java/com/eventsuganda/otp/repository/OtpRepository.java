package com.eventsuganda.otp.repository;

import com.eventsuganda.otp.model.Otp;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface OtpRepository extends JpaRepository<Otp, Long> {

    Optional<Otp> findTopByIdentifierOrderByCreatedAtDesc(String identifier);

    void deleteByIdentifier(String identifier);
}
