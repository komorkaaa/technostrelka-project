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

public class AuthActivity extends AppCompatActivity {
    private boolean isLoginMode = true;



    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_auth);
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
            startActivity(new Intent(this, MainPageActivity.class));
            finish();
        });
    }

    private void updateActionState(EditText email, EditText password, Button action) {
        boolean enabled = !email.getText().toString().trim().isEmpty()
                && !password.getText().toString().trim().isEmpty() && password.length() > 6;
        action.setEnabled(enabled);
    }
}
