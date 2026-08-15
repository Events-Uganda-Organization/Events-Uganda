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

    @Query("SELECT m.id FROM Message m WHERE m.conversationId = :conversationId AND m.senderId != :userId AND m.readAt IS NULL")
    List<String> findUnreadIds(@Param("conversationId") String conversationId, @Param("userId") String userId);

    @Modifying
    @Query("UPDATE Message m SET m.readAt = :readAt WHERE m.conversationId = :conversationId AND m.senderId != :userId AND m.readAt IS NULL")
    int markAsRead(@Param("conversationId") String conversationId, @Param("userId") String userId, @Param("readAt") long readAt);

    @Modifying
    @Query("DELETE FROM Message m WHERE m.conversationId = :conversationId")
    int deleteByConversationId(@Param("conversationId") String conversationId);

    @Query("SELECT m.id FROM Message m WHERE m.expiresAt IS NOT NULL AND m.expiresAt <= :now")
    List<String> findExpiredIds(@Param("now") long now);

    @Modifying
    @Query("DELETE FROM Message m WHERE m.expiresAt IS NOT NULL AND m.expiresAt <= :now")
    int deleteExpired(@Param("now") long now);

    @Query(value = """
            SELECT m.* FROM messages m
            JOIN conversations c ON c.id = m.conversation_id
            WHERE CONCAT(',', c.participant_ids, ',') LIKE CONCAT('%,', :userId, ',%')
              AND m.text IS NOT NULL
              AND m.text ILIKE CONCAT('%', :query, '%')
            ORDER BY m.created_at DESC
            """,
            countQuery = """
            SELECT COUNT(*) FROM messages m
            JOIN conversations c ON c.id = m.conversation_id
            WHERE CONCAT(',', c.participant_ids, ',') LIKE CONCAT('%,', :userId, ',%')
              AND m.text IS NOT NULL
              AND m.text ILIKE CONCAT('%', :query, '%')
            """,
            nativeQuery = true)
    List<Message> searchMessages(@Param("userId") String userId, @Param("query") String query, Pageable pageable);
}
