package com.ctrls.api;

import com.ctrls.api.dto.SubscriptionOut;
import java.util.List;

import retrofit2.Call;
import retrofit2.http.GET;
import retrofit2.http.Header;

public interface SubscriptionsApi {
    @GET("/subscriptions")
    Call<List<SubscriptionOut>> list(@Header("Authorization") String bearerToken);
}
