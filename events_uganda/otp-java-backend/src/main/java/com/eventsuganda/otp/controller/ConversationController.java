package com.eventsuganda.otp.controller;

import com.eventsuganda.otp.dto.request.CreateConversationRequest;
import com.eventsuganda.otp.dto.response.ApiResponse;
import com.eventsuganda.otp.dto.response.ConversationResponse;
import com.eventsuganda.otp.service.ConversationService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/api/chat")
public class ConversationController {

    private final ConversationService conversationService;

    public ConversationController(ConversationService conversationService) {
        this.conversationService = conversationService;
    }

    @PostMapping("/conversations")
    public ResponseEntity<ConversationResponse> createConversation(
            @Valid @RequestBody CreateConversationRequest request,
            Authentication auth) {
        String userId = (String) auth.getPrincipal();
        ConversationResponse response = conversationService.createConversation(
            request.getParticipantIds(), userId, request.getInitialMessage());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/conversations")
    public ResponseEntity<List<ConversationResponse>> getConversations(Authentication auth) {
        String userId = (String) auth.getPrincipal();
        return ResponseEntity.ok(conversationService.getConversations(userId));
    }

    @GetMapping("/conversations/{id}")
    public ResponseEntity<ConversationResponse> getConversation(
            @PathVariable String id, Authentication auth) {
        String userId = (String) auth.getPrincipal();
        return ResponseEntity.ok(conversationService.getConversation(id, userId));
    }
}
