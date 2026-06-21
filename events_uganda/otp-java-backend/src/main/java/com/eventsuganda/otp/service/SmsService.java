package com.eventsuganda.otp.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

@Service
public class SmsService {

    private final HttpClient client = HttpClient.newHttpClient();

    @Value("${sms.api.url:https://eventsuganda.netlify.app/.netlify/functions/send-otp}")
    private String smsApiUrl;

    public void sendOtpSms(String phone, String otp) {
        try {
            String json = "{\"phone\":\"%s\",\"otp\":\"%s\"}".formatted(phone, otp);

            HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(smsApiUrl))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();

            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() != 200) {
                throw new RuntimeException("SMS API returned status: " + response.statusCode());
            }
        } catch (Exception e) {
            throw new RuntimeException("Failed to send SMS: " + e.getMessage());
        }
    }
}
