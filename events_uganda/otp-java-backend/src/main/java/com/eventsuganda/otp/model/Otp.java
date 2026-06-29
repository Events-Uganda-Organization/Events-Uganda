package com.eventsuganda.otp.model;

import jakarta.persistence.*;

@Entity
@Table(name = "otps")
public class Otp {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String identifier;

    @Column(nullable = false)
    private String otpCode;

    @Column(nullable = false)
    private long createdAt;

    public Otp() {}

    public Otp(String identifier, String otpCode) {
        this.identifier = identifier;
        this.otpCode = otpCode;
        this.createdAt = System.currentTimeMillis();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getIdentifier() { return identifier; }
    public void setIdentifier(String identifier) { this.identifier = identifier; }

    public String getOtpCode() { return otpCode; }
    public void setOtpCode(String otpCode) { this.otpCode = otpCode; }

    public long getCreatedAt() { return createdAt; }
    public void setCreatedAt(long createdAt) { this.createdAt = createdAt; }
}
