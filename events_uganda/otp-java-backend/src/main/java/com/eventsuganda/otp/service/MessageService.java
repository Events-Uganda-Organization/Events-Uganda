package com.eventsuganda.otp.service;

import com.eventsuganda.otp.dto.response.ChatSearchResponse;
import com.eventsuganda.otp.dto.response.ConversationResponse;
import com.eventsuganda.otp.dto.response.MessageResponse;
import com.eventsuganda.otp.exception.OtpException;
import com.eventsuganda.otp.model.Conversation;
import com.eventsuganda.otp.model.Message;
import com.eventsuganda.otp.model.MessageMedia;
import com.eventsuganda.otp.model.Report;
import com.eventsuganda.otp.model.User;
import com.eventsuganda.otp.model.UserBlock;
import com.eventsuganda.otp.repository.ConversationRepository;
import com.eventsuganda.otp.repository.MessageMediaRepository;
import com.eventsuganda.otp.repository.MessageRepository;
import com.eventsuganda.otp.repository.ReportRepository;
import com.eventsuganda.otp.repository.UserBlockRepository;
import com.eventsuganda.otp.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.imageio.IIOImage;
import javax.imageio.ImageIO;
import javax.imageio.ImageWriteParam;
import javax.imageio.ImageWriter;
import javax.imageio.stream.ImageOutputStream;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class MessageService {

    private static final long MAX_MEDIA_BYTES = 8L * 1024 * 1024;
    private static final Set<String> IMAGE_MIME_TYPES = Set.of(
        "image/jpeg", "image/png", "image/webp", "image/gif");
    private static final Set<String> AUDIO_MIME_TYPES = Set.of(
        "audio/mp4", "audio/aac", "audio/webm", "audio/ogg", "audio/mpeg", "audio/x-m4a");

    private final MessageRepository messageRepository;
    private final ConversationRepository conversationRepository;
    private final MessageMediaRepository messageMediaRepository;
    private final PresenceService presenceService;
    private final UserBlockRepository userBlockRepository;
    private final ReportRepository reportRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;

    public MessageService(MessageRepository messageRepository,
                          ConversationRepository conversationRepository,
                          MessageMediaRepository messageMediaRepository,
                          PresenceService presenceService,
                          UserBlockRepository userBlockRepository,
                          ReportRepository reportRepository,
                          UserRepository userRepository,
                          EmailService emailService) {
        this.messageRepository = messageRepository;
        this.conversationRepository = conversationRepository;
        this.messageMediaRepository = messageMediaRepository;
        this.presenceService = presenceService;
        this.userBlockRepository = userBlockRepository;
        this.reportRepository = reportRepository;
        this.userRepository = userRepository;
        this.emailService = emailService;
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

        ensureNotBlocked(conversation, senderId);

        long now = System.currentTimeMillis();
        String id = UUID.randomUUID().toString();
        Message message = new Message(id, conversationId, senderId, text.trim());
        message.setExpiresAt(disappearingExpiry(conversation, now));
        markDeliveryStatus(message, conversation);
        messageRepository.save(message);

        conversation.setLastMessage(text.trim());
        conversation.setLastMessageSenderId(senderId);
        conversation.setLastMessageAt(now);
        conversation.setUpdatedAt(now);
        conversationRepository.save(conversation);

        return new MessageResponse(message, senderId);
    }

    @Transactional
    public MessageResponse sendMedia(String conversationId, String senderId, String caption,
                                     byte[] data, String mediaType, String mimeType, Long durationMs) {
        Conversation conversation = conversationRepository.findById(conversationId)
            .orElseThrow(() -> new OtpException("Conversation not found"));

        if (!conversation.getParticipantIdSet().contains(senderId)) {
            throw new OtpException("Access denied");
        }

        boolean isImage = "IMAGE".equals(mediaType);
        boolean isAudio = "AUDIO".equals(mediaType);
        if (!isImage && !isAudio) {
            throw new OtpException("Invalid media type");
        }

        Set<String> allowedMime = isImage ? IMAGE_MIME_TYPES : AUDIO_MIME_TYPES;
        if (mimeType == null || !allowedMime.contains(mimeType.toLowerCase())) {
            throw new OtpException("Unsupported media format");
        }

        ensureNotBlocked(conversation, senderId);

        if (data == null || data.length == 0) {
            throw new OtpException("Media file is empty");
        }
        if (data.length > MAX_MEDIA_BYTES) {
            throw new OtpException("Media file exceeds the 8MB limit");
        }

        byte[] stored = data;
        String storedMime = mimeType;
        if (isImage) {
            ImageResult result = compressImage(data, mimeType);
            stored = result.bytes;
            storedMime = result.mimeType;
        }

        String messageId = UUID.randomUUID().toString();
        String text = caption == null ? null : caption.trim();
        Message message = new Message(messageId, conversationId, senderId, text);
        message.setExpiresAt(disappearingExpiry(conversation, System.currentTimeMillis()));
        markDeliveryStatus(message, conversation);
        messageRepository.save(message);

        MessageMedia media = new MessageMedia(UUID.randomUUID().toString(), messageId,
            mediaType, storedMime, stored, durationMs);
        messageMediaRepository.save(media);

        long now = System.currentTimeMillis();
        String preview = (text != null && !text.isEmpty()) ? text
            : (isImage ? "Photo" : "Voice message");
        conversation.setLastMessage(preview);
        conversation.setLastMessageSenderId(senderId);
        conversation.setLastMessageAt(now);
        conversation.setUpdatedAt(now);
        conversationRepository.save(conversation);

        return new MessageResponse(message, senderId, mediaUrl(media.getId()), mediaType, durationMs);
    }

    private void markDeliveryStatus(Message message, Conversation conversation) {
        if (message.getDeliveredAt() != null) {
            return;
        }
        for (String participant : conversation.getParticipantIdSet()) {
            if (!participant.equals(message.getSenderId()) && presenceService.isOnline(participant)) {
                message.setDeliveredAt(System.currentTimeMillis());
                return;
            }
        }
    }

    @Transactional(readOnly = true)
    public MessageMedia getMedia(String mediaId, String userId) {
        MessageMedia media = messageMediaRepository.findById(mediaId)
            .orElseThrow(() -> new OtpException("Media not found"));

        Message message = messageRepository.findById(media.getMessageId())
            .orElseThrow(() -> new OtpException("Media not found"));

        Conversation conversation = conversationRepository.findById(message.getConversationId())
            .orElseThrow(() -> new OtpException("Conversation not found"));

        if (!conversation.getParticipantIdSet().contains(userId)) {
            throw new OtpException("Access denied");
        }

        return media;
    }

    public List<MessageResponse> getMessages(String conversationId, String userId, int page, int size) {
        Conversation conversation = conversationRepository.findById(conversationId)
            .orElseThrow(() -> new OtpException("Conversation not found"));

        if (!conversation.getParticipantIdSet().contains(userId)) {
            throw new OtpException("Access denied");
        }

        List<Message> messages = messageRepository.findByConversationIdOrderByCreatedAtDesc(
            conversationId, PageRequest.of(page, size));

        Map<String, MessageMediaRepository.MediaMeta> metas = messages.isEmpty()
            ? Map.of()
            : messageMediaRepository.findMetaByMessageIdIn(
                    messages.stream().map(Message::getId).collect(Collectors.toList()))
                .stream()
                .collect(Collectors.toMap(
                    MessageMediaRepository.MediaMeta::getMessageId,
                    meta -> meta));

        return messages.stream()
            .map(m -> toResponseWithMedia(m, userId, metas.get(m.getId())))
            .collect(Collectors.toList());
    }

    @Transactional
    public List<String> markAsRead(String conversationId, String userId) {
        List<String> unreadIds = messageRepository.findUnreadIds(conversationId, userId);
        if (unreadIds.isEmpty()) {
            return unreadIds;
        }
        messageRepository.markAsRead(conversationId, userId, System.currentTimeMillis());
        return unreadIds;
    }

    @Transactional
    public int clearChat(String conversationId, String userId) {
        Conversation conversation = findParticipantConversation(conversationId, userId);
        int deleted = messageRepository.deleteByConversationId(conversationId);
        conversation.setLastMessage(null);
        conversation.setLastMessageSenderId(null);
        conversation.setLastMessageAt(null);
        conversation.setUpdatedAt(System.currentTimeMillis());
        conversationRepository.save(conversation);
        return deleted;
    }

    @Transactional
    public void setDisappearingMode(String conversationId, String userId, String mode) {
        String normalized = mode == null ? "OFF" : mode.toUpperCase();
        if (!Set.of("OFF", "24H", "7D").contains(normalized)) {
            throw new OtpException("Invalid disappearing mode");
        }
        Conversation conversation = findParticipantConversation(conversationId, userId);
        conversation.setDisappearingMode(normalized);
        conversation.setUpdatedAt(System.currentTimeMillis());
        conversationRepository.save(conversation);
    }

    @Transactional
    public void blockUser(String conversationId, String userId) {
        Conversation conversation = findParticipantConversation(conversationId, userId);
        String other = otherParticipant(conversation, userId);
        if (other == null) {
            throw new OtpException("Cannot block a group conversation");
        }
        if (!userBlockRepository.existsByBlockerIdAndBlockedId(userId, other)) {
            userBlockRepository.save(new UserBlock(userId, other));
        }
    }

    @Transactional
    public void unblockUser(String conversationId, String userId) {
        Conversation conversation = findParticipantConversation(conversationId, userId);
        String other = otherParticipant(conversation, userId);
        if (other != null) {
            userBlockRepository.deleteByBlockerIdAndBlockedId(userId, other);
        }
    }

    @Transactional
    public void reportUser(String conversationId, String userId, String reason) {
        Conversation conversation = findParticipantConversation(conversationId, userId);
        String other = otherParticipant(conversation, userId);
        if (other == null) {
            throw new OtpException("Cannot report a group conversation");
        }
        reportRepository.save(new Report(userId, other, conversationId, reason));
        User reporter = userRepository.findById(userId).orElse(null);
        User reported = userRepository.findById(other).orElse(null);
        emailService.sendReportEmail(
            reporter != null ? reporter.getFullName() : null,
            reporter != null ? reporter.getEmail() : null,
            reported != null ? reported.getFullName() : null,
            reported != null ? reported.getEmail() : null,
            reason);
    }

    private void ensureNotBlocked(Conversation conversation, String userId) {
        conversation.getParticipantIdSet().stream()
            .filter(p -> !p.equals(userId))
            .findFirst()
            .ifPresent(other -> {
                if (userBlockRepository.existsByBlockerIdAndBlockedId(userId, other)
                        || userBlockRepository.existsByBlockerIdAndBlockedId(other, userId)) {
                    throw new OtpException("Messaging is not available with this user");
                }
            });
    }

    private Long disappearingExpiry(Conversation conversation, long now) {
        long durationMillis = switch (conversation.getDisappearingMode()) {
            case "24H" -> 24L * 60 * 60 * 1000;
            case "7D" -> 7L * 24 * 60 * 60 * 1000;
            default -> 0L;
        };
        return durationMillis > 0 ? now + durationMillis : null;
    }

    private Conversation findParticipantConversation(String conversationId, String userId) {
        Conversation conversation = conversationRepository.findById(conversationId)
            .orElseThrow(() -> new OtpException("Conversation not found"));
        if (!conversation.getParticipantIdSet().contains(userId)) {
            throw new OtpException("Access denied");
        }
        return conversation;
    }

    private String otherParticipant(Conversation conversation, String userId) {
        return conversation.getParticipantIdSet().stream()
            .filter(p -> !p.equals(userId))
            .findFirst()
            .orElse(null);
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

    private MessageResponse toResponseWithMedia(Message message, String userId,
                                                MessageMediaRepository.MediaMeta meta) {
        if (meta == null) {
            return new MessageResponse(message, userId);
        }
        return new MessageResponse(message, userId, mediaUrl(meta.getId()), meta.getMediaType(), meta.getDurationMs());
    }

    private String mediaUrl(String mediaId) {
        return "/api/chat/media/" + mediaId;
    }

    private static final int IMAGE_MAX_DIM = 1280;
    private static final float JPEG_QUALITY = 0.82f;
    private static final float WEBP_QUALITY = 0.80f;

    private ImageResult compressImage(byte[] original, String mimeType) {
        if ("image/gif".equalsIgnoreCase(mimeType)) {
            return new ImageResult(original, mimeType);
        }
        try {
            BufferedImage image = ImageIO.read(new ByteArrayInputStream(original));
            if (image == null || image.getWidth() <= 0 || image.getHeight() <= 0) {
                return new ImageResult(original, mimeType);
            }
            int width = image.getWidth();
            int height = image.getHeight();
            double scale = Math.min(1.0, IMAGE_MAX_DIM / (double) Math.max(width, height));
            int newWidth = Math.max(1, (int) Math.round(width * scale));
            int newHeight = Math.max(1, (int) Math.round(height * scale));

            BufferedImage resized = new BufferedImage(newWidth, newHeight, BufferedImage.TYPE_INT_RGB);
            Graphics2D g = resized.createGraphics();
            g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            g.setColor(Color.WHITE);
            g.fillRect(0, 0, newWidth, newHeight);
            g.drawImage(image, 0, 0, newWidth, newHeight, null);
            g.dispose();

            byte[] jpeg = encodeImage(resized, "image/jpeg", JPEG_QUALITY);
            byte[] webp = encodeImage(resized, "image/webp", WEBP_QUALITY);
            byte[] best = jpeg;
            String bestMime = "image/jpeg";
            if (webp != null && (best == null || webp.length < best.length)) {
                best = webp;
                bestMime = "image/webp";
            }
            if (best == null || original.length < best.length) {
                return new ImageResult(original, mimeType);
            }
            return new ImageResult(best, bestMime);
        } catch (IOException e) {
            return new ImageResult(original, mimeType);
        }
    }

    private byte[] encodeImage(BufferedImage image, String mimeType, float quality) {
        try {
            ImageWriter writer = ImageIO.getImageWritersByMIMEType(mimeType).next();
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            ImageOutputStream ios = ImageIO.createImageOutputStream(out);
            writer.setOutput(ios);
            ImageWriteParam param = writer.getDefaultWriteParam();
            param.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
            if (param.canWriteCompressed()) {
                String[] types = param.getCompressionTypes();
                if (types != null && types.length > 0) {
                    param.setCompressionType(types[0]);
                }
                param.setCompressionQuality(quality);
            }
            writer.write(null, new IIOImage(image, null, null), param);
            ios.flush();
            writer.dispose();
            return out.toByteArray();
        } catch (Exception e) {
            return null;
        }
    }

    public record RecompressResult(int processed, int shrunk, int skipped, long savedBytes) {}

    @Transactional
    public RecompressResult recompressImages(int batchSize) {
        int page = 0;
        int processed = 0;
        int shrunk = 0;
        int skipped = 0;
        long savedBytes = 0;
        while (true) {
            List<MessageMedia> batch = messageMediaRepository.findByMediaTypeOrderByCreatedAtAsc(
                "IMAGE", PageRequest.of(page, batchSize));
            if (batch.isEmpty()) {
                break;
            }
            for (MessageMedia media : batch) {
                byte[] original = media.getData();
                String mime = media.getMimeType();
                if (original == null || original.length == 0) {
                    skipped++;
                    continue;
                }
                ImageResult result = compressImage(original, mime == null ? "image/jpeg" : mime);
                processed++;
                if (result.bytes.length < original.length) {
                    media.setData(result.bytes);
                    media.setMimeType(result.mimeType);
                    messageMediaRepository.save(media);
                    shrunk++;
                    savedBytes += original.length - result.bytes.length;
                } else {
                    skipped++;
                }
            }
            page++;
            if (batch.size() < batchSize) {
                break;
            }
        }
        return new RecompressResult(processed, shrunk, skipped, savedBytes);
    }

    private static class ImageResult {
        private final byte[] bytes;
        private final String mimeType;

        ImageResult(byte[] bytes, String mimeType) {
            this.bytes = bytes;
            this.mimeType = mimeType;
        }
    }

    private ConversationResponse toConversationResponse(Conversation conversation, String userId) {
        long unread = messageRepository.countByConversationIdAndSenderIdNotAndReadAtIsNull(conversation.getId(), userId);
        return new ConversationResponse(conversation, unread);
    }
}
