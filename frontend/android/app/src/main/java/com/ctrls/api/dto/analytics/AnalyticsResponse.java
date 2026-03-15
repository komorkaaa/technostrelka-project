package com.ctrls.api.dto.analytics;

import java.util.Map;

public class AnalyticsResponse {
    public Map<String, Double> by_category;
    public Map<String, Double> by_service;
    public AnalyticsPeriodTotals totals;
}
