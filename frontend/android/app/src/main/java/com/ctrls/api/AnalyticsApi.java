package com.ctrls.api;

import com.ctrls.api.dto.analytics.AnalyticsChartResponse;
import com.ctrls.api.dto.analytics.AnalyticsResponse;

import retrofit2.Call;
import retrofit2.http.GET;
import retrofit2.http.Header;
import retrofit2.http.Query;

public interface AnalyticsApi {
    @GET("/analytics")
    Call<AnalyticsResponse> getAnalytics(@Header("Authorization") String bearerToken);

    @GET("/analytics/chart")
    Call<AnalyticsChartResponse> getChart(
            @Header("Authorization") String bearerToken,
            @Query("period") String period,
            @Query("category") String category
    );
}
