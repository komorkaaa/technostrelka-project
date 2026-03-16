package com.ctrls.api;

import com.ctrls.api.dto.SubscriptionCreateRequest;
import com.ctrls.api.dto.SubscriptionOut;
import java.util.List;

import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.GET;
import retrofit2.http.Header;
import retrofit2.http.POST;

public interface SubscriptionsApi {
    @GET("/subscriptions")
    Call<List<SubscriptionOut>> list(@Header("Authorization") String bearerToken);

    @POST("/subscriptions")
    Call<SubscriptionOut> create(
            @Header("Authorization") String bearerToken,
            @Body SubscriptionCreateRequest request
    );
}
