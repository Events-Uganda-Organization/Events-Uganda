package com.eventsuganda.otp.controller;

import com.eventsuganda.otp.dto.response.ApiResponse;
import com.eventsuganda.otp.dto.response.MessageResponse;
import com.eventsuganda.otp.exception.OtpException;
import com.eventsuganda.otp.model.Conversation;
import com.eventsuganda.otp.model.MessageMedia;
import com.eventsuganda.otp.repository.ConversationRepository;
import com.eventsuganda.otp.service.MessageService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.concurrent.TimeUnit;

@RestController
@RequestMapping("/api/chat")
public class MediaController {

    private static final Logger log = LoggerFactory.getLogger(MediaController.class);

    private final MessageService messageService;
    private final ConversationRepository conversationRepository;
    private final SimpMessagingTemplate messagingTemplate;

    @Value("${app.admin-token:}")
    private String adminToken;

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
        log.info("Media upload request received, conversationId={}, userId={}, type={}, contentType={}, size={}",
            conversationId, userId, type, file.getContentType(), file.getSize());

        try {
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
                .ifPresent(participants -> participants.forEach(participant -> {
                    try {
                        messagingTemplate.convertAndSendToUser(
                            participant, "/queue/messages", response);
                    } catch (Exception e) {
                        log.error("Failed to broadcast media message to participant {}, mediaId={}",
                            participant, response.getId(), e);
                    }
                }));

            return ResponseEntity.ok(response);
        } catch (IOException e) {
            log.error("Failed to read uploaded media file, conversationId={}, userId={}, type={}, size={}",
                conversationId, userId, type, file.getSize(), e);
            throw new OtpException("Could not read uploaded file");
        }
    }

    @GetMapping("/media/{mediaId}")
    public ResponseEntity<byte[]> download(
            @PathVariable String mediaId,
            Authentication auth,
            @RequestHeader(value = HttpHeaders.IF_NONE_MATCH, required = false) String ifNoneMatch) {
        String userId = (String) auth.getPrincipal();
        MessageMedia media = messageService.getMedia(mediaId, userId);
        String etag = "\"" + media.getId() + "-" + media.getData().length + "-" + media.getCreatedAt() + "\"";
        if (etag.equals(ifNoneMatch)) {
            return ResponseEntity.status(HttpStatus.NOT_MODIFIED).eTag(etag).build();
        }
        return ResponseEntity.ok()
            .contentType(MediaType.parseMediaType(media.getMimeType()))
            .cacheControl(CacheControl.maxAge(365, TimeUnit.DAYS).cachePublic())
            .header(HttpHeaders.CONTENT_DISPOSITION, "inline")
            .eTag(etag)
            .body(media.getData());
    }

    @PostMapping("/admin/media/recompress")
    public ResponseEntity<ApiResponse> recompressMedia(
            @RequestHeader(value = "X-Admin-Token", required = false) String token) {
        if (adminToken == null || adminToken.isEmpty() || !constantTimeEquals(adminToken, token)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResponse.error("Unauthorized"));
        }
        MessageService.RecompressResult result = messageService.recompressImages(20);
        return ResponseEntity.ok(ApiResponse.ok(
            "Recompressed " + result.processed() + " items, shrank " + result.shrunk()
                + ", saved " + result.savedBytes() + " bytes",
            result));
    }

    private boolean constantTimeEquals(String expected, String actual) {
        if (expected == null || actual == null) {
            return false;
        }
        return MessageDigest.isEqual(
            expected.getBytes(StandardCharsets.UTF_8),
            actual.getBytes(StandardCharsets.UTF_8));
    }
}
