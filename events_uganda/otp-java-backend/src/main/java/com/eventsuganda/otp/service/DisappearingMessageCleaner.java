package com.eventsuganda.otp.service;

import com.eventsuganda.otp.repository.MessageMediaRepository;
import com.eventsuganda.otp.repository.MessageRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class DisappearingMessageCleaner {

    private static final Logger log = LoggerFactory.getLogger(DisappearingMessageCleaner.class);

    private final MessageRepository messageRepository;
    private final MessageMediaRepository messageMediaRepository;

    public DisappearingMessageCleaner(MessageRepository messageRepository,
                                      MessageMediaRepository messageMediaRepository) {
        this.messageRepository = messageRepository;
        this.messageMediaRepository = messageMediaRepository;
    }

    @Scheduled(fixedDelay = 60_000)
    @Transactional
    public void purgeExpired() {
        try {
            long now = System.currentTimeMillis();
            List<String> expiredIds = messageRepository.findExpiredIds(now);
            if (expiredIds.isEmpty()) {
                return;
            }
            messageMediaRepository.deleteByMessageIdIn(expiredIds);
            int deleted = messageRepository.deleteExpired(now);
            log.info("Purged {} expired messages, {} media candidates, {} messages deleted",
                expiredIds.size(), expiredIds.size(), deleted);
        } catch (Exception e) {
            log.error("Failed to purge expired messages", e);
        }
    }
}
