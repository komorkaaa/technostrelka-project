package com.ctrls;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.text.Editable;
import android.text.TextWatcher;
import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import android.widget.Toast;

import com.ctrls.api.ApiClient;
import com.ctrls.api.AuthApi;
import com.ctrls.api.dto.RegisterRequest;
import com.ctrls.api.dto.TokenResponse;
import com.ctrls.api.dto.UserOut;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

import android.content.SharedPreferences;

public class AuthActivity extends AppCompatActivity {
    private boolean isLoginMode = true;
    private AuthApi authApi;
    private static final String PREFS = "auth_prefs";
    private static final String KEY_TOKEN = "access_token";


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_auth);
        authApi = ApiClient.getRetrofit().create(AuthApi.class);
        SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        String savedToken = prefs.getString(KEY_TOKEN, null);
        if (savedToken != null && !savedToken.isEmpty()) {
            startActivity(new Intent(this, MainPageActivity.class));
            finish();
            return;
        }
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.auth_root), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            int baseLeft = v.getPaddingLeft();
            int baseTop = v.getPaddingTop();
            int baseRight = v.getPaddingRight();
            int baseBottom = v.getPaddingBottom();
            v.setPadding(
                    baseLeft + systemBars.left,
                    baseTop + systemBars.top,
                    baseRight + systemBars.right,
                    baseBottom + systemBars.bottom
            );
            return insets;
        });

        TextView tabLogin = findViewById(R.id.tab_login);
        TextView tabRegister = findViewById(R.id.tab_register);
        EditText phoneField = findViewById(R.id.auth_phone);
        Button actionButton = findViewById(R.id.auth_action);

        EditText emailField = findViewById(R.id.auth_email);
        EditText passwordField = findViewById(R.id.auth_password);

        TextWatcher watcher = new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) { }
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) { }
            @Override public void afterTextChanged(Editable s) {
                updateActionState(emailField, passwordField, actionButton);
            }
        };

        emailField.addTextChangedListener(watcher);
        passwordField.addTextChangedListener(watcher);
        updateActionState(emailField, passwordField, actionButton);

        View.OnClickListener switchToLogin = v -> {
            isLoginMode = true;
            tabLogin.setBackgroundResource(R.drawable.bg_auth_toggle_active);
            tabRegister.setBackgroundResource(0);
            tabLogin.setTextColor(getColor(R.color.text_primary));
            tabRegister.setTextColor(getColor(R.color.text_secondary));
            phoneField.setVisibility(View.GONE);
            actionButton.setText(R.string.auth_action_login);
        };

        View.OnClickListener switchToRegister = v -> {
            isLoginMode = false;
            tabRegister.setBackgroundResource(R.drawable.bg_auth_toggle_active);
            tabLogin.setBackgroundResource(0);
            tabRegister.setTextColor(getColor(R.color.text_primary));
            tabLogin.setTextColor(getColor(R.color.text_secondary));
            phoneField.setVisibility(View.VISIBLE);
            actionButton.setText(R.string.auth_action_register);
        };

        tabLogin.setOnClickListener(switchToLogin);
        tabRegister.setOnClickListener(switchToRegister);

        actionButton.setOnClickListener(v -> {
            String email = emailField.getText().toString().trim();
            String password = passwordField.getText().toString().trim();
            String phone = phoneField.getText().toString().trim();

            actionButton.setEnabled(false);

            if (isLoginMode) {
                authApi.login(email, password).enqueue(new Callback<TokenResponse>() {
                    @Override
                    public void onResponse(Call<TokenResponse> call, Response<TokenResponse> response) {
                        actionButton.setEnabled(true);
                        if (response.isSuccessful() && response.body() != null) {
                            String token = response.body().access_token;
                            getSharedPreferences(PREFS, MODE_PRIVATE)
                                    .edit()
                                    .putString(KEY_TOKEN, token)
                                    .apply();
                            startActivity(new Intent(AuthActivity.this, MainPageActivity.class));
                            finish();
                        }
                        int code = response.code();
                        if (code == 401) {
                            Toast.makeText(AuthActivity.this, "Неверный логин или пароль", Toast.LENGTH_SHORT).show();
                        } else if (code == 404) {
                            Toast.makeText(AuthActivity.this, "Такого пользователя нет", Toast.LENGTH_SHORT).show();
                        }
//                        else {
//                            Toast.makeText(AuthActivity.this, "Ошибка входа", Toast.LENGTH_SHORT).show();
//                        }
                    }

                    @Override
                    public void onFailure(Call<TokenResponse> call, Throwable t) {
                        actionButton.setEnabled(true);
                        Toast.makeText(AuthActivity.this, "Ошибка сети", Toast.LENGTH_SHORT).show();
                    }
                });
            } else {
                RegisterRequest request = new RegisterRequest(email, password, phone.isEmpty() ? null : phone);
                authApi.register(request).enqueue(new Callback<UserOut>() {
                    @Override
                    public void onResponse(Call<UserOut> call, Response<UserOut> response) {
                        actionButton.setEnabled(true);
                        if (response.isSuccessful()) {
                            startActivity(new Intent(AuthActivity.this, MainPageActivity.class));
                            finish();
                        } int code = response.code();
                        if (code == 400) {
                            Toast.makeText(AuthActivity.this, "Такой email уже зарегистрирован", Toast.LENGTH_SHORT).show();
                        } else {
                            Toast.makeText(AuthActivity.this, "Ошибка регистрации", Toast.LENGTH_SHORT).show();
                        }
                    }

                    @Override
                    public void onFailure(Call<UserOut> call, Throwable t) {
                        actionButton.setEnabled(true);
                        Toast.makeText(AuthActivity.this, "Ошибка сети", Toast.LENGTH_SHORT).show();
                    }
                });
            }
        });
    }

    private void updateActionState(EditText email, EditText password, Button action) {
        boolean enabled = !email.getText().toString().trim().isEmpty()
                && !password.getText().toString().trim().isEmpty() && password.length() > 6;
        action.setEnabled(enabled);
    }
}
