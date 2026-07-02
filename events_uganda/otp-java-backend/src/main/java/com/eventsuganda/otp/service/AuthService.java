package com.eventsuganda.otp.service;

import com.eventsuganda.otp.dto.response.AuthResponse;
import com.eventsuganda.otp.exception.OtpException;
import com.eventsuganda.otp.model.User;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Map;

@Service
public class AuthService {

    private final UserService userService;
    private final JwtService jwtService;
    private final OtpService otpService;
    private final EmailService emailService;
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    public AuthService(UserService userService, JwtService jwtService, OtpService otpService, EmailService emailService) {
        this.userService = userService;
        this.jwtService = jwtService;
        this.otpService = otpService;
        this.emailService = emailService;
    }

    public AuthResponse register(String email, String password, String fullName, String phone, String referralCode) {
        String hashed = encoder.encode(password);
        User user = userService.createUser(email, hashed, fullName, phone, "email", referralCode);
        String token = jwtService.generateToken(user.getId(), user.getEmail());
        emailService.sendWelcomeEmail(user.getEmail(), user.getFullName());
        return new AuthResponse(token, user);
    }

    public AuthResponse login(String email, String password) {
        User user;
        try {
            user = userService.getByEmail(email);
        } catch (OtpException e) {
            user = userService.getByPhone(email);
        }

        if (!encoder.matches(password, user.getPassword())) {
            throw new OtpException("Invalid email or password");
        }

        String token = jwtService.generateToken(user.getId(), user.getEmail());
        return new AuthResponse(token, user);
    }

    public AuthResponse googleAuth(String idToken, String accessToken) {
        try {
            Map<String, Object> payload;

            if (accessToken != null && !accessToken.isBlank()) {
                HttpRequest tokenRequest = HttpRequest.newBuilder()
                    .uri(URI.create("https://www.googleapis.com/oauth2/v3/userinfo"))
                    .header("Authorization", "Bearer " + accessToken)
                    .GET()
                    .build();

                HttpResponse<String> tokenResponse = httpClient.send(tokenRequest, HttpResponse.BodyHandlers.ofString());

                if (tokenResponse.statusCode() != 200) {
                    throw new OtpException("Invalid Google access token");
                }

                @SuppressWarnings("unchecked")
                Map<String, Object> p = new com.fasterxml.jackson.databind.ObjectMapper()
                    .readValue(tokenResponse.body(), Map.class);
                payload = p;
            } else {
                HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create("https://oauth2.googleapis.com/tokeninfo?id_token=" + idToken))
                    .GET()
                    .build();

                HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

                if (response.statusCode() != 200) {
                    throw new OtpException("Invalid Google ID token");
                }

                @SuppressWarnings("unchecked")
                Map<String, Object> p = new com.fasterxml.jackson.databind.ObjectMapper()
                    .readValue(response.body(), Map.class);
                payload = p;
            }

            String email = (String) payload.get("email");
            String name = (String) payload.get("name");
            String picture = (String) payload.get("picture");

            if (email == null) {
                throw new OtpException("Google account has no email");
            }

            if (userService.emailExists(email)) {
                User existing = userService.getByEmail(email);
                String token = jwtService.generateToken(existing.getId(), existing.getEmail());
                return new AuthResponse(token, existing);
            }

            User newUser = userService.createUser(email, null, name, "", "google");
            newUser.setPhotoUrl(picture);

            String token = jwtService.generateToken(newUser.getId(), newUser.getEmail());
            return new AuthResponse(token, newUser);
        } catch (OtpException e) {
            throw e;
        } catch (Exception e) {
            throw new OtpException("Google authentication failed: " + e.getMessage());
        }
    }

    public void resetPassword(String email, String otp, String newPassword) {
        otpService.verify("email:" + email, otp);
        User user = userService.getByEmail(email);
        String hashed = encoder.encode(newPassword);
        userService.updatePassword(email, hashed);
        emailService.sendPasswordResetConfirmation(user.getEmail(), user.getFullName());
    }
}
