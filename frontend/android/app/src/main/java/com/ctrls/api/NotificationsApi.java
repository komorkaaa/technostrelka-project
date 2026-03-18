package com.ctrls.api;

import com.ctrls.api.dto.UpcomingNotificationsResponse;

import retrofit2.Call;
import retrofit2.http.GET;
import retrofit2.http.Header;
import retrofit2.http.Query;

public interface NotificationsApi {
    @GET("/notifications/upcoming")
    Call<UpcomingNotificationsResponse> upcoming(
            @Header("Authorization") String bearerToken,
            @Query("days") int days
    );
}
