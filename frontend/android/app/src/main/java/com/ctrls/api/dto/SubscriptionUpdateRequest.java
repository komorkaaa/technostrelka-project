package com.ctrls.api.dto;

public class SubscriptionUpdateRequest {
    public String next_billing_date;

    public SubscriptionUpdateRequest(String next_billing_date) {
        this.next_billing_date = next_billing_date;
    }
}
