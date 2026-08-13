package com.eventsuganda.otp.service;

import com.eventsuganda.otp.dto.response.ChatSearchResponse;
import com.eventsuganda.otp.dto.response.ConversationResponse;
import com.eventsuganda.otp.dto.response.MessageResponse;
import com.eventsuganda.otp.exception.OtpException;
import com.eventsuganda.otp.model.Conversation;
import com.eventsuganda.otp.model.Message;
import com.eventsuganda.otp.model.MessageMedia;
import com.eventsuganda.otp.repository.ConversationRepository;
import com.eventsuganda.otp.repository.MessageMediaRepository;
import com.eventsuganda.otp.repository.MessageRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.imageio.ImageIO;
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

    public MessageService(MessageRepository messageRepository,
                          ConversationRepository conversationRepository,
                          MessageMediaRepository messageMediaRepository) {
        this.messageRepository = messageRepository;
        this.conversationRepository = conversationRepository;
        this.messageMediaRepository = messageMediaRepository;
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

        if (data == null || data.length == 0) {
            throw new OtpException("Media file is empty");
        }
        if (data.length > MAX_MEDIA_BYTES) {
            throw new OtpException("Media file exceeds the 8MB limit");
        }

        byte[] stored = isImage ? compressImage(data, mimeType) : data;

        String messageId = UUID.randomUUID().toString();
        String text = caption == null ? null : caption.trim();
        Message message = new Message(messageId, conversationId, senderId, text);
        messageRepository.save(message);

        MessageMedia media = new MessageMedia(UUID.randomUUID().toString(), messageId,
            mediaType, mimeType, stored, durationMs);
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

    private byte[] compressImage(byte[] original, String mimeType) {
        if ("image/gif".equalsIgnoreCase(mimeType)) {
            return original;
        }
        try {
            BufferedImage image = ImageIO.read(new ByteArrayInputStream(original));
            if (image == null) {
                return original;
            }
            int maxDim = 1280;
            int width = image.getWidth();
            int height = image.getHeight();
            if (width <= maxDim && height <= maxDim && "image/jpeg".equalsIgnoreCase(mimeType)) {
                return original;
            }
            double scale = Math.min(1.0, maxDim / (double) Math.max(width, height));
            int newWidth = Math.max(1, (int) Math.round(width * scale));
            int newHeight = Math.max(1, (int) Math.round(height * scale));

            BufferedImage resized = new BufferedImage(newWidth, newHeight, BufferedImage.TYPE_INT_RGB);
            Graphics2D g = resized.createGraphics();
            g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            g.drawImage(image, 0, 0, newWidth, newHeight, null);
            g.dispose();

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            ImageIO.write(resized, "jpg", out);
            return out.toByteArray();
        } catch (IOException e) {
            return original;
        }
    }

    private ConversationResponse toConversationResponse(Conversation conversation, String userId) {
        long unread = messageRepository.countByConversationIdAndSenderIdNotAndReadAtIsNull(conversation.getId(), userId);
        return new ConversationResponse(conversation, unread);
    }
}
