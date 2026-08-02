package com.eventsuganda.otp.repository;

import com.eventsuganda.otp.model.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, String> {

    List<Notification> findByUserIdAndArchivedAtIsNullOrderByCreatedAtDesc(String userId);

    List<Notification> findByUserIdAndArchivedAtIsNotNullOrderByCreatedAtDesc(String userId);

    List<Notification> findByUserIdOrderByCreatedAtDesc(String userId);

    long countByUserIdAndArchivedAtIsNullAndReadAtIsNull(String userId);

    @Modifying
    @Query("UPDATE Notification n SET n.readAt = :readAt WHERE n.userId = :userId AND n.readAt IS NULL")
    int markAllRead(@Param("userId") String userId, @Param("readAt") long readAt);

    @Modifying
    @Query("DELETE FROM Notification n WHERE n.userId = :userId AND n.readAt IS NOT NULL")
    int deleteAllRead(@Param("userId") String userId);
}
