package com.eventsuganda.otp.dto.response;

import com.eventsuganda.otp.model.User;

public class AuthResponse {

    private String token;
    private UserProfile user;

    public AuthResponse() {}

    public AuthResponse(String token, User user) {
        this.token = token;
        this.user = new UserProfile(user);
    }

    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }

    public UserProfile getUser() { return user; }
    public void setUser(UserProfile user) { this.user = user; }

    public static class UserProfile {
        private String id;
        private String email;
        private String fullName;
        private String phone;
        private String photoUrl;
        private String authProvider;
        private String referralCode;

        UserProfile(User user) {
            this.id = user.getId();
            this.email = user.getEmail();
            this.fullName = user.getFullName();
            this.phone = user.getPhone();
            this.photoUrl = user.getPhotoUrl();
            this.authProvider = user.getAuthProvider();
            this.referralCode = user.getReferralCode();
        }

        public String getId() { return id; }
        public String getEmail() { return email; }
        public String getFullName() { return fullName; }
        public String getPhone() { return phone; }
        public String getPhotoUrl() { return photoUrl; }
        public String getAuthProvider() { return authProvider; }
        public String getReferralCode() { return referralCode; }
    }
}
