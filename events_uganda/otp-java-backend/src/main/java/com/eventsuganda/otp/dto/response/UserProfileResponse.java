package com.eventsuganda.otp.dto.response;

import com.eventsuganda.otp.model.User;

public class UserProfileResponse {

    private String id;
    private String email;
    private String fullName;
    private String phone;
    private String photoUrl;
    private String authProvider;
    private String referralCode;

    public UserProfileResponse() {}

    public UserProfileResponse(User user) {
        this.id = user.getId();
        this.email = user.getEmail();
        this.fullName = user.getFullName();
        this.phone = user.getPhone();
        this.photoUrl = user.getPhotoUrl();
        this.authProvider = user.getAuthProvider();
        this.referralCode = user.getReferralCode();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getPhotoUrl() { return photoUrl; }
    public void setPhotoUrl(String photoUrl) { this.photoUrl = photoUrl; }

    public String getAuthProvider() { return authProvider; }
    public void setAuthProvider(String authProvider) { this.authProvider = authProvider; }

    public String getReferralCode() { return referralCode; }
    public void setReferralCode(String referralCode) { this.referralCode = referralCode; }
}
