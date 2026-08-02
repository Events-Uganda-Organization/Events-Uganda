package com.eventsuganda.otp.service;

import com.eventsuganda.otp.dto.response.ChatSearchResponse;
import com.eventsuganda.otp.dto.response.ConversationResponse;
import com.eventsuganda.otp.dto.response.MessageResponse;
import com.eventsuganda.otp.exception.OtpException;
import com.eventsuganda.otp.model.Conversation;
import com.eventsuganda.otp.model.Message;
import com.eventsuganda.otp.repository.ConversationRepository;
import com.eventsuganda.otp.repository.MessageRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class MessageService {

    private final MessageRepository messageRepository;
    private final ConversationRepository conversationRepository;

    public MessageService(MessageRepository messageRepository, ConversationRepository conversationRepository) {
        this.messageRepository = messageRepository;
        this.conversationRepository = conversationRepository;
    }

    @Transactional
    public MessageResponse sendMessage(String conversationId, String senderId, String text) {
        Conversation conversation = conversationRepository.findById(conversationId)
            .orElseThrow(() -> new OtpException("Conversation not found"));

        if (!conversation.getParticipantIdSet().contains(senderId)) {
            throw new OtpException("Access denied");
        }

        if (text == null || text.trim().isEmpty()) {
            throw new OtpException("Message text is required");
        }

        String id = UUID.randomUUID().toString();
        Message message = new Message(id, conversationId, senderId, text.trim());
        messageRepository.save(message);

        long now = System.currentTimeMillis();
        conversation.setLastMessage(text.trim());
        conversation.setLastMessageSenderId(senderId);
        conversation.setLastMessageAt(now);
        conversation.setUpdatedAt(now);
        conversationRepository.save(conversation);

        return new MessageResponse(message, senderId);
    }

    public List<MessageResponse> getMessages(String conversationId, String userId, int page, int size) {
        Conversation conversation = conversationRepository.findById(conversationId)
            .orElseThrow(() -> new OtpException("Conversation not found"));

        if (!conversation.getParticipantIdSet().contains(userId)) {
            throw new OtpException("Access denied");
        }

        return messageRepository.findByConversationIdOrderByCreatedAtDesc(conversationId, PageRequest.of(page, size))
            .stream()
            .map(m -> new MessageResponse(m, userId))
            .collect(Collectors.toList());
    }

    @Transactional
    public int markAsRead(String conversationId, String userId) {
        return messageRepository.markAsRead(conversationId, userId, System.currentTimeMillis());
    }

    public ChatSearchResponse search(String userId, String query, int page, int size) {
        String q = query == null ? "" : query.trim();
        if (q.isEmpty()) {
            throw new OtpException("Search query is required");
        }

        List<ConversationResponse> conversations = conversationRepository.searchByLastMessage(userId, q)
            .stream()
            .map(c -> toConversationResponse(c, userId))
            .collect(Collectors.toList());

        List<MessageResponse> messages = messageRepository.searchMessages(userId, q, PageRequest.of(page, size))
            .stream()
            .map(m -> new MessageResponse(m, userId))
            .collect(Collectors.toList());

        return new ChatSearchResponse(conversations, messages);
    }

    private ConversationResponse toConversationResponse(Conversation conversation, String userId) {
        long unread = messageRepository.countByConversationIdAndSenderIdNotAndReadAtIsNull(conversation.getId(), userId);
        return new ConversationResponse(conversation, unread);
    }
}
