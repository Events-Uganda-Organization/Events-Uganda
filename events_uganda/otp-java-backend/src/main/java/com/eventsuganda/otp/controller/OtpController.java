package com.eventsuganda.otp.controller;

import com.eventsuganda.otp.model.ApiResponse;
import com.eventsuganda.otp.model.SendOtpRequest;
import com.eventsuganda.otp.model.VerifyOtpRequest;
import com.eventsuganda.otp.service.EmailService;
import com.eventsuganda.otp.service.OtpService;
import com.eventsuganda.otp.service.SmsService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/otp")
public class OtpController {

    private final OtpService otpService;
    private final EmailService emailService;
    private final SmsService smsService;

    public OtpController(OtpService otpService, EmailService emailService, SmsService smsService) {
        this.otpService = otpService;
        this.emailService = emailService;
        this.smsService = smsService;
    }

    @PostMapping("/send")
    public ResponseEntity<ApiResponse> sendOtp(@RequestBody SendOtpRequest request) {
        try {
            if (request.getEmail() != null && !request.getEmail().isBlank()) {
                String otp = otpService.generateOtp("email:" + request.getEmail());
                emailService.sendOtpEmail(request.getEmail(), otp);
                return ResponseEntity.ok(new ApiResponse(true, "OTP sent to your email"));
            } else if (request.getPhone() != null && !request.getPhone().isBlank()) {
                String otp = otpService.generateOtp("phone:" + request.getPhone());
                smsService.sendOtpSms(request.getPhone(), otp);
                return ResponseEntity.ok(new ApiResponse(true, "OTP sent to your phone"));
            } else {
                return ResponseEntity.badRequest()
                    .body(new ApiResponse(false, "Email or phone number is required"));
            }
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                .body(new ApiResponse(false, "Failed to send OTP: " + e.getMessage()));
        }
    }

    @PostMapping("/verify")
    public ResponseEntity<ApiResponse> verifyOtp(@RequestBody VerifyOtpRequest request) {
        if (request.getOtp() == null || request.getOtp().isBlank()) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "OTP is required"));
        }

        boolean valid;
        if (request.getEmail() != null && !request.getEmail().isBlank()) {
            valid = otpService.verifyOtp("email:" + request.getEmail(), request.getOtp());
        } else if (request.getPhone() != null && !request.getPhone().isBlank()) {
            valid = otpService.verifyOtp("phone:" + request.getPhone(), request.getOtp());
        } else {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Email or phone number is required"));
        }

        if (valid) {
            return ResponseEntity.ok(new ApiResponse(true, "OTP verified successfully"));
        } else {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Invalid or expired OTP"));
        }
    }
}
