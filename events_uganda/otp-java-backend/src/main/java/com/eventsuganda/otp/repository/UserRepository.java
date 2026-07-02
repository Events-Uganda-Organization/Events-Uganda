package com.eventsuganda.otp.repository;

import com.eventsuganda.otp.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, String> {

    Optional<User> findByEmail(String email);

    Optional<User> findByPhone(String phone);

    boolean existsByEmail(String email);

    boolean existsByReferralCode(String referralCode);

    Optional<User> findByReferralCode(String referralCode);
}
