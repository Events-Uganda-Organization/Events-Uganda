package com.eventsuganda.otp.service;

import com.eventsuganda.otp.repository.MessageRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DisappearingMessageCleaner {

    private static final Logger log = LoggerFactory.getLogger(DisappearingMessageCleaner.class);

    private final MessageRepository messageRepository;

    public DisappearingMessageCleaner(MessageRepository messageRepository) {
        this.messageRepository = messageRepository;
    }

    @Scheduled(fixedDelay = 60_000)
    @Transactional
    public void purgeExpired() {
        try {
            int deleted = messageRepository.deleteExpired(System.currentTimeMillis());
            if (deleted > 0) {
                log.info("Purged {} expired messages", deleted);
            }
        } catch (Exception e) {
            log.error("Failed to purge expired messages", e);
        }
    }
}
