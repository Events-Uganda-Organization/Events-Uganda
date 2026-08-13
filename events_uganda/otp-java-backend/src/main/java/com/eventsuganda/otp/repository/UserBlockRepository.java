package com.eventsuganda.otp.repository;

import com.eventsuganda.otp.model.UserBlock;
import com.eventsuganda.otp.model.UserBlockId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserBlockRepository extends JpaRepository<UserBlock, UserBlockId> {

    boolean existsByBlockerIdAndBlockedId(String blockerId, String blockedId);

    void deleteByBlockerIdAndBlockedId(String blockerId, String blockedId);
}
