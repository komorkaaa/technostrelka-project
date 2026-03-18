package com.ctrls.api.dto;

public class PasswordChangeRequest {
    public String current_password;
    public String new_password;

    public PasswordChangeRequest(String current_password, String new_password) {
        this.current_password = current_password;
        this.new_password = new_password;
    }
}
