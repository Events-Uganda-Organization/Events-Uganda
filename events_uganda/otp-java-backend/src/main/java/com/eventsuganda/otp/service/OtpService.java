package com.eventsuganda.otp.service;

import com.eventsuganda.otp.exception.OtpException;
import com.eventsuganda.otp.model.Otp;
import com.eventsuganda.otp.repository.OtpRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;

@Service
public class OtpService {

    private static final Logger log = LoggerFactory.getLogger(OtpService.class);

    private final OtpRepository otpRepository;
    private final SecureRandom random = new SecureRandom();

    private static final long OTP_VALIDITY_MS = 30 * 60 * 1000;
    private static final int OTP_LENGTH = 4;

    public OtpService(OtpRepository otpRepository) {
        this.otpRepository = otpRepository;
    }

    public String generateAndStore(String key) {
        int code = (int) Math.pow(10, OTP_LENGTH - 1) + random.nextInt((int) Math.pow(10, OTP_LENGTH) - (int) Math.pow(10, OTP_LENGTH - 1));
        String otp = String.valueOf(code);
        otpRepository.save(new Otp(key, otp));
        log.debug("OTP stored for key: {}", key);
        return otp;
    }

    public void verify(String key, String otp) {
        Otp entry = otpRepository.findTopByIdentifierOrderByCreatedAtDesc(key).orElse(null);
        if (entry == null) {
            throw new OtpException("No OTP found for this identifier");
        }

        if (System.currentTimeMillis() - entry.getCreatedAt() > OTP_VALIDITY_MS) {
            otpRepository.delete(entry);
            throw new OtpException("OTP has expired");
        }

        if (!entry.getOtpCode().equals(otp)) {
            throw new OtpException("Invalid OTP");
        }

        otpRepository.delete(entry);
        log.debug("OTP verified for key: {}", key);
    }
}
