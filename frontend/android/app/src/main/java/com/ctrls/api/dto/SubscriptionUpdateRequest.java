package com.ctrls.api.dto;

public class SubscriptionUpdateRequest {
    public String name;
    public Double amount;
    public String currency;
    public String billing_period;
    public String category;
    public String next_billing_date;
    public String status;

    public SubscriptionUpdateRequest(String next_billing_date) {
        this.next_billing_date = next_billing_date;
    }

    public SubscriptionUpdateRequest(
            String name,
            Double amount,
            String currency,
            String billing_period,
            String category,
            String next_billing_date,
            String status
    ) {
        this.name = name;
        this.amount = amount;
        this.currency = currency;
        this.billing_period = billing_period;
        this.category = category;
        this.next_billing_date = next_billing_date;
        this.status = status;
    }
}
