package com.eventsuganda.otp.service;

import com.eventsuganda.otp.exception.OtpException;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void sendOtp(String to, String otp) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail);
            helper.setTo(to);
            helper.setSubject("Your OTP Code - Events Uganda");

            String html = """
                <div style="font-family: Arial, sans-serif; padding: 20px;">
                  <h2>Password Reset OTP</h2>
                  <p>Your OTP code is:</p>
                  <h1 style="color: #D59A00; letter-spacing: 5px;">%s</h1>
                  <p>This code will expire in 10 minutes.</p>
                  <p>If you didn't request this, please ignore this email.</p>
                  <br>
                  <p>Best regards,<br/>Events Uganda Team</p>
                </div>
                """.formatted(otp);

            helper.setText(html, true);
            mailSender.send(message);

            log.info("OTP email sent to {}", to);
        } catch (Exception e) {
            log.error("Failed to send email to {}", to, e);
            throw new OtpException("Failed to send email: " + e.getMessage());
        }
    }
}
