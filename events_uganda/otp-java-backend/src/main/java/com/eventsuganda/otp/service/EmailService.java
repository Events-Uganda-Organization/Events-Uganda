package com.eventsuganda.otp.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import jakarta.mail.internet.MimeMessage;

@Service
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void sendOtpEmail(String to, String otp) {
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
        } catch (Exception e) {
            throw new RuntimeException("Failed to send email: " + e.getMessage());
        }
    }
}
