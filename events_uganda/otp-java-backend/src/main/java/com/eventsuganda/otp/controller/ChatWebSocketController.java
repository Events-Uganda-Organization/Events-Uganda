package com.eventsuganda.otp.controller;

import com.eventsuganda.otp.dto.request.ChatMessageRequest;
import com.eventsuganda.otp.dto.response.MessageResponse;
import com.eventsuganda.otp.model.Conversation;
import com.eventsuganda.otp.repository.ConversationRepository;
import com.eventsuganda.otp.service.MessageService;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import java.security.Principal;

@Controller
public class ChatWebSocketController {

    private final MessageService messageService;
    private final ConversationRepository conversationRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public ChatWebSocketController(MessageService messageService,
                                   ConversationRepository conversationRepository,
                                   SimpMessagingTemplate messagingTemplate) {
        this.messageService = messageService;
        this.conversationRepository = conversationRepository;
        this.messagingTemplate = messagingTemplate;
    }

    @MessageMapping("/chat.sendMessage")
    public void sendMessage(@Payload ChatMessageRequest request, Principal principal) {
        if (principal == null || request == null || request.getConversationId() == null) {
            return;
        }
        String senderId = principal.getName();
        MessageResponse response = messageService.sendMessage(
            request.getConversationId(), senderId, request.getText());

        messagingTemplate.convertAndSend("/topic/chat/" + request.getConversationId(), response);

        conversationRepository.findById(request.getConversationId())
            .map(Conversation::getParticipantIdSet)
            .ifPresent(participants -> participants.forEach(participant ->
                messagingTemplate.convertAndSendToUser(participant, "/queue/messages", response)));
    }
}
