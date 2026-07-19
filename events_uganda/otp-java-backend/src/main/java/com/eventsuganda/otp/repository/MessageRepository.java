package com.eventsuganda.otp.repository;

import com.eventsuganda.otp.model.Message;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MessageRepository extends JpaRepository<Message, String> {

    List<Message> findByConversationIdOrderByCreatedAtDesc(String conversationId, Pageable pageable);

    @Query("SELECT m FROM Message m WHERE m.conversationId = :conversationId ORDER BY m.createdAt ASC")
    List<Message> findByConversationIdOrderByCreatedAtAsc(@Param("conversationId") String conversationId);

    long countByConversationIdAndSenderIdNotAndReadAtIsNull(String conversationId, String senderId);

    @Modifying
    @Query("UPDATE Message m SET m.readAt = :readAt WHERE m.conversationId = :conversationId AND m.senderId != :userId AND m.readAt IS NULL")
    int markAsRead(@Param("conversationId") String conversationId, @Param("userId") String userId, @Param("readAt") long readAt);
}
