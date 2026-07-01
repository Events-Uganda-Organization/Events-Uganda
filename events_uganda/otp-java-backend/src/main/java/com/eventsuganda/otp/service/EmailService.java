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

    public void sendWelcomeEmail(String to, String fullName) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail);
            helper.setTo(to);
            helper.setSubject("Welcome to Events Uganda!");

            String html = """
                <div style="font-family: Arial, sans-serif; padding: 20px; max-width: 600px; margin: auto;">
                  <h2 style="color: #D59A00;">Welcome to Events Uganda!</h2>
                  <p>Hi %s,</p>
                  <p>Thank you for signing up with <strong>Events Uganda</strong>. We're thrilled to have you on board!</p>
                  <p>With Events Uganda, you can discover and book amazing events near you, from concerts and conferences to cultural festivals and more.</p>
                  <p>Here's what you can do next:</p>
                  <ul>
                    <li>Browse upcoming events</li>
                    <li>Save your favorite events</li>
                    <li>Share events with friends</li>
                  </ul>
                  <p>If you ever need help, feel free to reach out to our support team.</p>
                  <br>
                  <p>Best regards,<br/><strong>Events Uganda Team</strong></p>
                </div>
                """.formatted(fullName != null ? fullName : "there");

            helper.setText(html, true);
            mailSender.send(message);

            log.info("Welcome email sent to {}", to);
        } catch (Exception e) {
            log.error("Failed to send welcome email to {}", to, e);
        }
    }

    public void sendPasswordResetConfirmation(String to, String fullName) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail);
            helper.setTo(to);
            helper.setSubject("Password Reset Successful - Events Uganda");

            String html = """
                <div style="font-family: Arial, sans-serif; padding: 20px; max-width: 600px; margin: auto;">
                  <h2 style="color: #D59A00;">Password Reset Successful</h2>
                  <p>Hi %s,</p>
                  <p>Your password has been successfully reset.</p>
                  <p>If you did not request this change, please contact our support team immediately.</p>
                  <br>
                  <p>Best regards,<br/><strong>Events Uganda Team</strong></p>
                </div>
                """.formatted(fullName != null ? fullName : "there");

            helper.setText(html, true);
            mailSender.send(message);

            log.info("Password reset confirmation email sent to {}", to);
        } catch (Exception e) {
            log.error("Failed to send password reset confirmation email to {}", to, e);
        }
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
