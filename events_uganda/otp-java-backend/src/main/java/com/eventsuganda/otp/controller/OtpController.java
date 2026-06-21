package com.eventsuganda.otp.controller;

import com.eventsuganda.otp.dto.request.SendOtpRequest;
import com.eventsuganda.otp.dto.request.VerifyOtpRequest;
import com.eventsuganda.otp.dto.response.ApiResponse;
import com.eventsuganda.otp.service.EmailService;
import com.eventsuganda.otp.service.OtpService;
import com.eventsuganda.otp.service.SmsService;
import jakarta.validation.Valid;
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
    public ResponseEntity<ApiResponse> sendOtp(@Valid @RequestBody SendOtpRequest request) {
        if (request.getEmail() != null && !request.getEmail().isBlank()) {
            String otp = otpService.generateAndStore("email:" + request.getEmail());
            emailService.sendOtp(request.getEmail(), otp);
            return ResponseEntity.ok(ApiResponse.ok("OTP sent to your email"));
        }

        String otp = otpService.generateAndStore("phone:" + request.getPhone());
        smsService.sendOtp(request.getPhone(), otp);
        return ResponseEntity.ok(ApiResponse.ok("OTP sent to your phone"));
    }

    @PostMapping("/verify")
    public ResponseEntity<ApiResponse> verifyOtp(@Valid @RequestBody VerifyOtpRequest request) {
        if (request.getEmail() != null && !request.getEmail().isBlank()) {
            otpService.verify("email:" + request.getEmail(), request.getOtp());
        } else {
            otpService.verify("phone:" + request.getPhone(), request.getOtp());
        }
        return ResponseEntity.ok(ApiResponse.ok("OTP verified successfully"));
    }
}
