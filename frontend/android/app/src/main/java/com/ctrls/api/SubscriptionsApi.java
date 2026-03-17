package com.ctrls.api;

import com.ctrls.api.dto.SubscriptionCreateRequest;
import com.ctrls.api.dto.SubscriptionOut;
import com.ctrls.api.dto.SubscriptionUpdateRequest;
import java.util.List;

import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.DELETE;
import retrofit2.http.GET;
import retrofit2.http.Header;
import retrofit2.http.POST;
import retrofit2.http.PUT;
import retrofit2.http.Path;

public interface SubscriptionsApi {
    @GET("/subscriptions")
    Call<List<SubscriptionOut>> list(@Header("Authorization") String bearerToken);

    @POST("/subscriptions")
    Call<SubscriptionOut> create(
            @Header("Authorization") String bearerToken,
            @Body SubscriptionCreateRequest request
    );

    @PUT("/subscriptions/{id}")
    Call<SubscriptionOut> update(
            @Header("Authorization") String bearerToken,
            @Path("id") int id,
            @Body SubscriptionUpdateRequest request
    );

    @DELETE("/subscriptions/{id}")
    Call<Void> delete(
            @Header("Authorization") String bearerToken,
            @Path("id") int id
    );
}
