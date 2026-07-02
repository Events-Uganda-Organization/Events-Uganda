package com.eventsuganda.otp.controller;

import com.eventsuganda.otp.dto.request.GoogleAuthRequest;
import com.eventsuganda.otp.dto.request.LoginRequest;
import com.eventsuganda.otp.dto.request.RegisterRequest;
import com.eventsuganda.otp.dto.request.ResetPasswordRequest;
import com.eventsuganda.otp.dto.response.ApiResponse;
import com.eventsuganda.otp.dto.response.AuthResponse;
import com.eventsuganda.otp.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        AuthResponse response = authService.register(
            request.getEmail(),
            request.getPassword(),
            request.getFullName(),
            request.getPhone(),
            request.getReferralCode()
        );
        return ResponseEntity.ok(response);
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse response = authService.login(request.getEmail(), request.getPassword());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/google")
    public ResponseEntity<AuthResponse> googleAuth(@Valid @RequestBody GoogleAuthRequest request) {
        AuthResponse response = authService.googleAuth(request.getIdToken(), request.getAccessToken());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/reset-password")
    public ResponseEntity<ApiResponse> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        authService.resetPassword(request.getEmail(), request.getOtp(), request.getNewPassword());
        return ResponseEntity.ok(ApiResponse.ok("Password reset successfully"));
    }
}
