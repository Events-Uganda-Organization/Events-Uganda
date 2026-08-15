package com.eventsuganda.otp.repository;

import com.eventsuganda.otp.model.Call;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CallRepository extends JpaRepository<Call, String> {
}
