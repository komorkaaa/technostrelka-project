package com.ctrls.api;

import com.ctrls.api.dto.RegisterRequest;
import com.ctrls.api.dto.TokenResponse;
import com.ctrls.api.dto.UserOut;

import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.Field;
import retrofit2.http.FormUrlEncoded;
import retrofit2.http.GET;
import retrofit2.http.POST;
import retrofit2.http.Header;
import retrofit2.http.PATCH;
import com.ctrls.api.dto.ProfileUpdateRequest;
import com.ctrls.api.dto.PasswordChangeRequest;

public interface AuthApi {
    @POST("/auth/register")
    Call<UserOut> register(@Body RegisterRequest request);

    @FormUrlEncoded
    @POST("/auth/login")
    Call<TokenResponse> login(
            @Field("username") String email,
            @Field("password") String password
    );

    @GET("/auth/me")
    Call<UserOut> me(@Header("Authorization") String bearerToken);

    @PATCH("/auth/me")
    Call<UserOut> updateMe(
            @Header("Authorization") String bearerToken,
            @Body ProfileUpdateRequest request
    );

    @POST("/auth/change-password")
    Call<Void> changePassword(
            @Header("Authorization") String bearerToken,
            @Body PasswordChangeRequest request
    );
}
