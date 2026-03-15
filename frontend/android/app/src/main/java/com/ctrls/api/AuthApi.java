package com.ctrls.api;

import com.ctrls.api.dto.RegisterRequest;
import com.ctrls.api.dto.TokenResponse;
import com.ctrls.api.dto.UserOut;

import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.Field;
import retrofit2.http.FormUrlEncoded;
import retrofit2.http.POST;

public interface AuthApi {
    @POST("/auth/register")
    Call<UserOut> register(@Body RegisterRequest request);

    @FormUrlEncoded
    @POST("/auth/login")
    Call<TokenResponse> login(
            @Field("username") String email,
            @Field("password") String password
    );
}
