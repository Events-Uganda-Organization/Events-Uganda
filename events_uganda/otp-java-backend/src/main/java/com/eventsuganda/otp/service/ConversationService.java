package com.eventsuganda.otp.service;

import com.eventsuganda.otp.dto.response.ConversationResponse;
import com.eventsuganda.otp.exception.OtpException;
import com.eventsuganda.otp.model.Conversation;
import com.eventsuganda.otp.model.Message;
import com.eventsuganda.otp.repository.ConversationRepository;
import com.eventsuganda.otp.repository.MessageRepository;
import com.eventsuganda.otp.repository.UserBlockRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class ConversationService {

    private final ConversationRepository conversationRepository;
    private final MessageRepository messageRepository;
    private final UserBlockRepository userBlockRepository;

    public ConversationService(ConversationRepository conversationRepository,
                               MessageRepository messageRepository,
                               UserBlockRepository userBlockRepository) {
        this.conversationRepository = conversationRepository;
        this.messageRepository = messageRepository;
        this.userBlockRepository = userBlockRepository;
    }

    @Transactional
    public ConversationResponse createConversation(Set<String> participantIds, String currentUserId, String initialMessage) {
        participantIds.add(currentUserId);

        if (participantIds.size() < 2) {
            throw new OtpException("Conversation requires at least 2 participants");
        }

        List<String> sorted = participantIds.stream().sorted().collect(Collectors.toList());

        if (sorted.size() == 2) {
            Optional<Conversation> existing = conversationRepository.findByTwoParticipants(sorted.get(0), sorted.get(1));
            if (existing.isPresent()) {
                return toResponse(existing.get(), currentUserId);
            }
        }

        String id = UUID.randomUUID().toString();
        Conversation conversation = new Conversation(id, participantIds);
        conversationRepository.save(conversation);

        if (initialMessage != null && !initialMessage.trim().isEmpty()) {
            String text = initialMessage.trim();
            Message message = new Message(UUID.randomUUID().toString(), id, currentUserId, text);
            messageRepository.save(message);

            long now = message.getCreatedAt();
            conversation.setLastMessage(text);
            conversation.setLastMessageSenderId(currentUserId);
            conversation.setLastMessageAt(now);
            conversation.setUpdatedAt(now);
            conversationRepository.save(conversation);
        }

        return toResponse(conversation, currentUserId);
    }

    public List<ConversationResponse> getConversations(String userId) {
        return conversationRepository.findByParticipantId(userId).stream()
            .map(c -> toResponse(c, userId))
            .collect(Collectors.toList());
    }

    public ConversationResponse getConversation(String conversationId, String userId) {
        Conversation conversation = conversationRepository.findById(conversationId)
            .orElseThrow(() -> new OtpException("Conversation not found"));

        if (!conversation.getParticipantIdSet().contains(userId)) {
            throw new OtpException("Access denied");
        }

        return toResponse(conversation, userId);
    }

    private ConversationResponse toResponse(Conversation conversation, String userId) {
        long unread = messageRepository.countByConversationIdAndSenderIdNotAndReadAtIsNull(conversation.getId(), userId);
        ConversationResponse response = new ConversationResponse(conversation, unread);
        conversation.getParticipantIdSet().stream()
            .filter(p -> !p.equals(userId))
            .findFirst()
            .ifPresent(other -> response.setBlocked(
                userBlockRepository.existsByBlockerIdAndBlockedId(userId, other)));
        return response;
    }
}
