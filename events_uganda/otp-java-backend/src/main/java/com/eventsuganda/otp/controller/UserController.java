package com.eventsuganda.otp.controller;

import com.eventsuganda.otp.dto.response.UserProfileResponse;
import com.eventsuganda.otp.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public ResponseEntity<UserProfileResponse> me(Authentication auth) {
        String userId = (String) auth.getPrincipal();
        return ResponseEntity.ok(new UserProfileResponse(userService.getById(userId)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserProfileResponse> getById(@PathVariable String id) {
        return ResponseEntity.ok(new UserProfileResponse(userService.getById(id)));
    }
}
