package com.ctrls.api;

import com.ctrls.api.dto.EmailImportRequest;
import com.ctrls.api.dto.EmailImportResult;

import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.Header;
import retrofit2.http.POST;

public interface EmailApi {
    @POST("/email/import")
    Call<EmailImportResult> importEmails(
            @Header("Authorization") String bearerToken,
            @Body EmailImportRequest request
    );
}
