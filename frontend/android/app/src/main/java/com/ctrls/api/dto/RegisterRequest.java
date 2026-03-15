package com.ctrls.api.dto;

public class RegisterRequest {
    public String email;
    public String password;
    public String phone;

    public RegisterRequest(String email, String password, String phone) {
        this.email = email;
        this.password = password;
        this.phone = phone;
    }
}
