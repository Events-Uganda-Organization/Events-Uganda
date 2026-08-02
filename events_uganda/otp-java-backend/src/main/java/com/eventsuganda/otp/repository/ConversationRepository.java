package com.eventsuganda.otp.repository;

import com.eventsuganda.otp.model.Conversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ConversationRepository extends JpaRepository<Conversation, String> {

    @Query("SELECT c FROM Conversation c WHERE c.participantIds LIKE %:userId% ORDER BY c.updatedAt DESC")
    List<Conversation> findByParticipantId(@Param("userId") String userId);

    @Query("SELECT c FROM Conversation c WHERE c.participantIds LIKE %:user1% AND c.participantIds LIKE %:user2%")
    Optional<Conversation> findByTwoParticipants(@Param("user1") String user1, @Param("user2") String user2);

    @Query("SELECT COUNT(c) FROM Conversation c WHERE c.participantIds LIKE %:userId% AND c.lastMessageSenderId != :userId AND (c.lastMessageAt IS NOT NULL AND (SELECT COUNT(m) FROM Message m WHERE m.conversationId = c.id AND m.senderId != :userId AND m.readAt IS NULL) > 0)")
    long countUnreadByUserId(@Param("userId") String userId);

    @Query(value = """
            SELECT c.* FROM conversations c
            WHERE CONCAT(',', c.participant_ids, ',') LIKE CONCAT('%,', :userId, ',%')
              AND c.last_message IS NOT NULL
              AND c.last_message ILIKE CONCAT('%', :query, '%')
            ORDER BY c.updated_at DESC
            """,
            nativeQuery = true)
    List<Conversation> searchByLastMessage(@Param("userId") String userId, @Param("query") String query);
}
