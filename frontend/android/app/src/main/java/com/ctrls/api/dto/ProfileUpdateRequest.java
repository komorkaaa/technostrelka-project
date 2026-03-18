package com.ctrls.api.dto;

public class ProfileUpdateRequest {
    public String email;
    public String phone;

    public ProfileUpdateRequest(String email, String phone) {
        this.email = email;
        this.phone = phone;
    }
}
