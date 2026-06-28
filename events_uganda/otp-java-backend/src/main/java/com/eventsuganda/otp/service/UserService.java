package com.eventsuganda.otp.service;

import com.eventsuganda.otp.exception.OtpException;
import com.eventsuganda.otp.model.User;
import com.eventsuganda.otp.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User createUser(String email, String password, String fullName, String phone, String authProvider) {
        if (userRepository.existsByEmail(email)) {
            throw new OtpException("Email already registered");
        }

        String id = UUID.randomUUID().toString();
        User user = new User(id, email, password, fullName, phone, authProvider);
        return userRepository.save(user);
    }

    public User getByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new OtpException("User not found"));
    }

    public User getById(String id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new OtpException("User not found"));
    }

    public void updatePassword(String email, String newPassword) {
        User user = getByEmail(email);
        user.setPassword(newPassword);
        userRepository.save(user);
    }

    public boolean emailExists(String email) {
        return userRepository.existsByEmail(email);
    }

    public User getByPhone(String phone) {
        return userRepository.findByPhone(phone)
                .orElseThrow(() -> new OtpException("User not found with phone: " + phone));
    }
}
