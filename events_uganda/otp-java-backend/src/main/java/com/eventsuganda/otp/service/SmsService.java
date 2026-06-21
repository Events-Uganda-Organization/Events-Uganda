package com.eventsuganda.otp.service;

import com.eventsuganda.otp.exception.OtpException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

@Service
public class SmsService {

    private static final Logger log = LoggerFactory.getLogger(SmsService.class);

    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Value("${sms.api.url}")
    private String smsApiUrl;

    public void sendOtp(String phone, String otp) {
        try {
            String json = "{\"phone\":\"%s\",\"otp\":\"%s\"}".formatted(phone, otp);

            HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(smsApiUrl))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() != 200) {
                throw new OtpException("SMS API returned status: " + response.statusCode());
            }

            log.info("OTP SMS sent to {}", phone);
        } catch (OtpException e) {
            throw e;
        } catch (Exception e) {
            log.error("Failed to send SMS to {}", phone, e);
            throw new OtpException("Failed to send SMS: " + e.getMessage());
        }
    }
}
