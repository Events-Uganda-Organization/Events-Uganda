package com.eventsuganda.otp.service;

import com.eventsuganda.otp.dto.response.ConversationResponse;
import com.eventsuganda.otp.exception.OtpException;
import com.eventsuganda.otp.model.Conversation;
import com.eventsuganda.otp.repository.ConversationRepository;
import com.eventsuganda.otp.repository.MessageRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class ConversationService {

    private final ConversationRepository conversationRepository;
    private final MessageRepository messageRepository;

    public ConversationService(ConversationRepository conversationRepository, MessageRepository messageRepository) {
        this.conversationRepository = conversationRepository;
        this.messageRepository = messageRepository;
    }

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
        return new ConversationResponse(conversation, unread);
    }
}
