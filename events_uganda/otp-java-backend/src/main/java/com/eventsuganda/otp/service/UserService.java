package com.eventsuganda.otp.service;

import com.eventsuganda.otp.exception.OtpException;
import com.eventsuganda.otp.model.User;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class UserService {

    private final Map<String, User> usersByEmail = new ConcurrentHashMap<>();
    private final Map<String, User> usersById = new ConcurrentHashMap<>();

    public User createUser(String email, String password, String fullName, String phone, String authProvider) {
        if (usersByEmail.containsKey(email)) {
            throw new OtpException("Email already registered");
        }

        String id = UUID.randomUUID().toString();
        User user = new User(id, email, password, fullName, phone, authProvider);
        usersByEmail.put(email, user);
        usersById.put(id, user);
        return user;
    }

    public User getByEmail(String email) {
        User user = usersByEmail.get(email);
        if (user == null) {
            throw new OtpException("User not found");
        }
        return user;
    }

    public User getById(String id) {
        User user = usersById.get(id);
        if (user == null) {
            throw new OtpException("User not found");
        }
        return user;
    }

    public void updatePassword(String email, String newPassword) {
        User user = getByEmail(email);
        user.setPassword(newPassword);
    }

    public boolean emailExists(String email) {
        return usersByEmail.containsKey(email);
    }
}
