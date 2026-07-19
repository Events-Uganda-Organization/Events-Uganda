package com.eventsuganda.otp.controller;

import com.eventsuganda.otp.dto.request.SendMessageRequest;
import com.eventsuganda.otp.dto.response.ApiResponse;
import com.eventsuganda.otp.dto.response.MessageResponse;
import com.eventsuganda.otp.service.MessageService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/api/chat")
public class MessageController {

    private final MessageService messageService;

    public MessageController(MessageService messageService) {
        this.messageService = messageService;
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
        int updated = messageService.markAsRead(conversationId, userId);
        return ResponseEntity.ok(ApiResponse.ok(updated + " messages marked as read"));
    }
}
