package com.eventsuganda.otp.controller;

import com.eventsuganda.otp.dto.response.MessageResponse;
import com.eventsuganda.otp.model.Conversation;
import com.eventsuganda.otp.model.MessageMedia;
import com.eventsuganda.otp.repository.ConversationRepository;
import com.eventsuganda.otp.service.MessageService;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

@RestController
@RequestMapping("/api/chat")
public class MediaController {

    private final MessageService messageService;
    private final ConversationRepository conversationRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public MediaController(MessageService messageService,
                           ConversationRepository conversationRepository,
                           SimpMessagingTemplate messagingTemplate) {
        this.messageService = messageService;
        this.conversationRepository = conversationRepository;
        this.messagingTemplate = messagingTemplate;
    }

    @PostMapping("/conversations/{conversationId}/media")
    public ResponseEntity<MessageResponse> upload(
            @PathVariable String conversationId,
            @RequestParam String type,
            @RequestParam(required = false) String caption,
            @RequestParam(required = false) Long durationMs,
            @RequestParam("file") MultipartFile file,
            Authentication auth) throws IOException {
        String userId = (String) auth.getPrincipal();

        MessageResponse response = messageService.sendMedia(
            conversationId,
            userId,
            caption,
            file.getBytes(),
            type.toUpperCase(),
            file.getContentType(),
            durationMs);

        conversationRepository.findById(conversationId)
            .map(Conversation::getParticipantIdSet)
            .ifPresent(participants -> participants.forEach(participant ->
                messagingTemplate.convertAndSendToUser(participant, "/queue/messages", response)));

        return ResponseEntity.ok(response);
    }

    @GetMapping("/media/{mediaId}")
    public ResponseEntity<byte[]> download(@PathVariable String mediaId, Authentication auth) {
        String userId = (String) auth.getPrincipal();
        MessageMedia media = messageService.getMedia(mediaId, userId);
        return ResponseEntity.ok()
            .contentType(MediaType.parseMediaType(media.getMimeType()))
            .cacheControl(CacheControl.maxAge(365, TimeUnit.DAYS).cachePublic())
            .header(HttpHeaders.CONTENT_DISPOSITION, "inline")
            .body(media.getData());
    }
}
