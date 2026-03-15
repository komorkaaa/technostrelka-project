package com.ctrls.api.dto.analytics;

import java.util.List;

public class AnalyticsChartResponse {
    public String period;
    public AnalyticsPeriodTotals totals;
    public List<AnalyticsChartPoint> series;
    public String category;
}