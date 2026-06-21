package com.eventsuganda.otp.dto.request;

public class GoogleAuthRequest {

    private String idToken;
    private String accessToken;

    public String getIdToken() { return idToken; }
    public void setIdToken(String idToken) { this.idToken = idToken; }
    public String getAccessToken() { return accessToken; }
    public void setAccessToken(String accessToken) { this.accessToken = accessToken; }
}
