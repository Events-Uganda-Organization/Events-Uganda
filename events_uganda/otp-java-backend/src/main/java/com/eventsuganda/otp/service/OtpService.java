package com.eventsuganda.otp.service;

import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class OtpService {

    private final Map<String, OtpEntry> otpStore = new ConcurrentHashMap<>();
    private final SecureRandom random = new SecureRandom();

    private static final long OTP_VALIDITY_MINUTES = 10;

    public String generateOtp(String key) {
        int code = 1000 + random.nextInt(9000);
        String otp = String.valueOf(code);
        otpStore.put(key, new OtpEntry(otp, System.currentTimeMillis()));
        return otp;
    }

    public boolean verifyOtp(String key, String otp) {
        OtpEntry entry = otpStore.get(key);
        if (entry == null) return false;

        long elapsed = System.currentTimeMillis() - entry.createdAt;
        if (elapsed > OTP_VALIDITY_MINUTES * 60 * 1000) {
            otpStore.remove(key);
            return false;
        }

        if (!entry.otp.equals(otp)) return false;

        otpStore.remove(key);
        return true;
    }

    private static class OtpEntry {
        final String otp;
        final long createdAt;

        OtpEntry(String otp, long createdAt) {
            this.otp = otp;
            this.createdAt = createdAt;
        }
    }
}
