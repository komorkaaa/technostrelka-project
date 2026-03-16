package com.ctrls.api.dto;

public class SubscriptionCreateRequest {
    public String name;
    public double amount;
    public String currency;
    public String billing_period;
    public String category;
    public String next_billing_date;

    public SubscriptionCreateRequest(String name, double amount, String currency,
                                     String billing_period, String category, String next_billing_date) {
        this.name = name;
        this.amount = amount;
        this.currency = currency;
        this.billing_period = billing_period;
        this.category = category;
        this.next_billing_date = next_billing_date;
    }
}
