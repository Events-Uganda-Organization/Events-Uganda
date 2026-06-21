package com.eventsuganda.otp.service;

import com.eventsuganda.otp.exception.OtpException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class OtpService {

    private static final Logger log = LoggerFactory.getLogger(OtpService.class);

    private final Map<String, OtpEntry> otpStore = new ConcurrentHashMap<>();
    private final SecureRandom random = new SecureRandom();

    private static final long OTP_VALIDITY_MS = 10 * 60 * 1000;
    private static final int OTP_LENGTH = 4;

    public String generateAndStore(String key) {
        int code = (int) Math.pow(10, OTP_LENGTH - 1) + random.nextInt((int) Math.pow(10, OTP_LENGTH) - (int) Math.pow(10, OTP_LENGTH - 1));
        String otp = String.valueOf(code);
        otpStore.put(key, new OtpEntry(otp, System.currentTimeMillis()));
        log.debug("OTP stored for key: {}", key);
        return otp;
    }

    public void verify(String key, String otp) {
        OtpEntry entry = otpStore.get(key);
        if (entry == null) {
            throw new OtpException("No OTP found for this identifier");
        }

        if (System.currentTimeMillis() - entry.createdAt > OTP_VALIDITY_MS) {
            otpStore.remove(key);
            throw new OtpException("OTP has expired");
        }

        if (!entry.otp.equals(otp)) {
            throw new OtpException("Invalid OTP");
        }

        otpStore.remove(key);
        log.debug("OTP verified for key: {}", key);
    }

    private record OtpEntry(String otp, long createdAt) {}
}
