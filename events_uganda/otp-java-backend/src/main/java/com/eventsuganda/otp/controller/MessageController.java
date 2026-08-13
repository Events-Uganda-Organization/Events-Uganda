package com.eventsuganda.otp.controller;

import com.eventsuganda.otp.dto.request.DisappearingModeRequest;
import com.eventsuganda.otp.dto.request.ReportRequest;
import com.eventsuganda.otp.dto.request.SendMessageRequest;
import com.eventsuganda.otp.dto.response.ApiResponse;
import com.eventsuganda.otp.dto.response.ChatSearchResponse;
import com.eventsuganda.otp.dto.response.MessageResponse;
import com.eventsuganda.otp.model.Conversation;
import com.eventsuganda.otp.repository.ConversationRepository;
import com.eventsuganda.otp.service.MessageService;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
public class MessageController {

    private final MessageService messageService;
    private final ConversationRepository conversationRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public MessageController(MessageService messageService,
                             ConversationRepository conversationRepository,
                             SimpMessagingTemplate messagingTemplate) {
        this.messageService = messageService;
        this.conversationRepository = conversationRepository;
        this.messagingTemplate = messagingTemplate;
    }

    @PostMapping("/conversations/{conversationId}/messages")
    public ResponseEntity<MessageResponse> sendMessage(
            @PathVariable String conversationId,
            @Valid @RequestBody SendMessageRequest request,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        MessageResponse response = messageService.sendMessage(conversationId, userId, request.getText());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/conversations/{conversationId}/messages")
    public ResponseEntity<List<MessageResponse>> getMessages(
            @PathVariable String conversationId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        return ResponseEntity.ok(messageService.getMessages(conversationId, userId, page, size));
    }

    @PostMapping("/conversations/{conversationId}/read")
    public ResponseEntity<ApiResponse> markAsRead(
            @PathVariable String conversationId,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        List<String> messageIds = messageService.markAsRead(conversationId, userId);
        if (!messageIds.isEmpty()) {
            long readAt = System.currentTimeMillis();
            Map<String, Object> payload = Map.of(
                "conversationId", conversationId,
                "readAt", readAt);
            conversationRepository.findById(conversationId)
                .map(Conversation::getParticipantIdSet)
                .ifPresent(participants -> participants.stream()
                    .filter(participant -> !participant.equals(userId))
                    .forEach(participant ->
                        messagingTemplate.convertAndSendToUser(
                            participant, "/queue/message-status", payload)));
        }
        return ResponseEntity.ok(ApiResponse.ok(messageIds.size() + " messages marked as read"));
    }

    @GetMapping("/search")
    public ResponseEntity<ChatSearchResponse> search(
            @RequestParam("q") String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        return ResponseEntity.ok(messageService.search(userId, query, page, size));
    }

    @DeleteMapping("/conversations/{conversationId}/messages")
    public ResponseEntity<ApiResponse> clearChat(
            @PathVariable String conversationId,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        int deleted = messageService.clearChat(conversationId, userId);
        return ResponseEntity.ok(ApiResponse.ok(deleted + " messages cleared"));
    }

    @PutMapping("/conversations/{conversationId}/disappearing")
    public ResponseEntity<ApiResponse> setDisappearingMode(
            @PathVariable String conversationId,
            @Valid @RequestBody DisappearingModeRequest request,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        messageService.setDisappearingMode(conversationId, userId, request.getMode());
        return ResponseEntity.ok(ApiResponse.ok("Disappearing messages updated"));
    }

    @PostMapping("/conversations/{conversationId}/block")
    public ResponseEntity<ApiResponse> blockUser(
            @PathVariable String conversationId,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        messageService.blockUser(conversationId, userId);
        return ResponseEntity.ok(ApiResponse.ok("User blocked"));
    }

    @PostMapping("/conversations/{conversationId}/unblock")
    public ResponseEntity<ApiResponse> unblockUser(
            @PathVariable String conversationId,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        messageService.unblockUser(conversationId, userId);
        return ResponseEntity.ok(ApiResponse.ok("User unblocked"));
    }

    @PostMapping("/conversations/{conversationId}/report")
    public ResponseEntity<ApiResponse> reportUser(
            @PathVariable String conversationId,
            @Valid @RequestBody ReportRequest request,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        messageService.reportUser(conversationId, userId, request.getReason());
        return ResponseEntity.ok(ApiResponse.ok("Report submitted. Thank you for keeping the community safe."));
    }
}
