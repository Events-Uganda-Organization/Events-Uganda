package com.eventsuganda.otp.service;

import com.eventsuganda.otp.exception.OtpException;
import com.eventsuganda.otp.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.Random;

@Service
public class ReferralCodeService {

    private final UserRepository userRepository;
    private final Random random = new Random();

    public ReferralCodeService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    /**
     * Generates a unique referral code in format: UG + 2 digits + 2 letters + 2 digits
     * Example: UG12AB34
     */
    public String generateReferralCode() {
        String code;
        int attempts = 0;
        final int maxAttempts = 100;

        do {
            code = generateCode();
            attempts++;
            if (attempts > maxAttempts) {
                throw new OtpException("Failed to generate unique referral code after " + maxAttempts + " attempts");
            }
        } while (userRepository.existsByReferralCode(code));

        return code;
    }

    private String generateCode() {
        // Format: UG + 2 digits + 2 letters + 2 digits
        StringBuilder code = new StringBuilder("UG");
        
        // 2 digits
        code.append(random.nextInt(90) + 10); // 10-99
        
        // 2 letters
        code.append((char) (random.nextInt(26) + 'A'));
        code.append((char) (random.nextInt(26) + 'A'));
        
        // 2 digits
        code.append(random.nextInt(90) + 10); // 10-99
        
        return code.toString();
    }
}
