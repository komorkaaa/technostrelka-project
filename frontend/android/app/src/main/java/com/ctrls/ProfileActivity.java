package com.ctrls;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;

import com.ctrls.api.ApiClient;
import com.ctrls.api.AuthApi;
import com.ctrls.api.AnalyticsApi;
import com.ctrls.api.NotificationsApi;
import com.ctrls.api.SubscriptionsApi;
import com.ctrls.api.EmailApi;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.ctrls.api.dto.UpcomingNotificationItem;
import com.ctrls.api.dto.UpcomingNotificationsResponse;
import com.ctrls.api.dto.SubscriptionOut;
import com.ctrls.api.dto.UserOut;
import com.ctrls.api.dto.ProfileUpdateRequest;
import com.ctrls.api.dto.PasswordChangeRequest;
import com.ctrls.api.dto.EmailImportRequest;
import com.ctrls.api.dto.EmailImportResult;
import com.ctrls.api.dto.analytics.AnalyticsResponse;
import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.google.android.material.bottomsheet.BottomSheetDialog;

import android.content.SharedPreferences;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.RadioGroup;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;
import java.text.DecimalFormat;
import java.util.List;
import java.util.Locale;

public class ProfileActivity extends AppCompatActivity {

    private static final String PREFS = "auth_prefs";
    private static final String KEY_TOKEN = "access_token";
    private final DecimalFormat moneyFormat = new DecimalFormat("#,###.##");
    private String currentEmail = "";
    private String currentPhone = "";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_profile);
        View bell = findViewById(R.id.notification);
        if (bell != null) {
            bell.setOnClickListener(v -> openNotificationsBottomSheet());
        }
        View personal = findViewById(R.id.row_personal);
        if (personal != null) {
            personal.setOnClickListener(v -> openEditProfileSheet());
        }
        View security = findViewById(R.id.row_security);
        if (security != null) {
            security.setOnClickListener(v -> openChangePasswordSheet());
        }
        View importRow = findViewById(R.id.row_import);
        if (importRow != null) {
            importRow.setOnClickListener(v -> openEmailImportSheet());
        }
        View logout = findViewById(R.id.logout_button);
        logout.setOnClickListener(v -> {
            SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
            prefs.edit().remove(KEY_TOKEN).apply();

            Intent intent = new Intent(ProfileActivity.this, AuthActivity.class);
            intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
            finish();
        });

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.profile_root), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, 0);

            View content = findViewById(R.id.profile_scroll);
            if (content != null) {
                content.setPadding(
                        content.getPaddingLeft(),
                        content.getPaddingTop(),
                        content.getPaddingRight(),
                        systemBars.bottom
                );
            }
            return insets;
        });

        BottomNavigationView nav = findViewById(R.id.bottom_nav);
        nav.setSelectedItemId(R.id.nav_profile);

        nav.setOnItemSelectedListener(item -> {
            int id = item.getItemId();
            if (id == R.id.nav_home) {
                startActivity(new Intent(this, MainPageActivity.class));
                finish(); return true;
            }
            if (id == R.id.nav_subs) {
                startActivity(new Intent(this, SubscriptionActivity.class));
                finish(); return true;
            }
            if (id == R.id.nav_calendar) {
                startActivity(new Intent(this, CalendarActivity.class));
                finish(); return true;
            }
            if (id == R.id.nav_analytics) {
                startActivity(new Intent(this, AnalyticsActivity.class));
                finish(); return true;
            }
            if (id == R.id.nav_profile) {
                return true;
            }
            return true;
        });

        loadProfileSummary();
    }

    private void loadProfileSummary() {
        SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        String token = prefs.getString(KEY_TOKEN, null);
        if (token == null || token.isEmpty()) {
            startActivity(new Intent(this, AuthActivity.class));
            finish();
            return;
        }

        AuthApi authApi = ApiClient.getRetrofit().create(AuthApi.class);
        SubscriptionsApi subscriptionsApi = ApiClient.getRetrofit().create(SubscriptionsApi.class);
        AnalyticsApi analyticsApi = ApiClient.getRetrofit().create(AnalyticsApi.class);

        authApi.me("Bearer " + token).enqueue(new retrofit2.Callback<UserOut>() {
            @Override
            public void onResponse(retrofit2.Call<UserOut> call, retrofit2.Response<UserOut> response) {
                if (response.isSuccessful() && response.body() != null) {
                    currentEmail = response.body().email == null ? "" : response.body().email;
                    currentPhone = response.body().phone == null ? "" : response.body().phone;
                    TextView email = findViewById(R.id.profile_email);
                    if (email != null) {
                        email.setText(currentEmail);
                    }
                    TextView avatar = findViewById(R.id.profile_avatar_letter);
                    if (avatar != null && !currentEmail.isEmpty()) {
                        String first = currentEmail.substring(0, 1).toUpperCase();
                        avatar.setText(first);
                    }
                }
            }

            @Override
            public void onFailure(retrofit2.Call<UserOut> call, Throwable t) { }
        });

        subscriptionsApi.list("Bearer " + token).enqueue(new retrofit2.Callback<List<SubscriptionOut>>() {
            @Override
            public void onResponse(retrofit2.Call<List<SubscriptionOut>> call, retrofit2.Response<List<SubscriptionOut>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    TextView subs = findViewById(R.id.stat_subs_value);
                    if (subs != null) {
                        subs.setText(String.valueOf(response.body().size()));
                    }
                }
            }

            @Override
            public void onFailure(retrofit2.Call<List<SubscriptionOut>> call, Throwable t) { }
        });

        analyticsApi.getAnalytics("Bearer " + token).enqueue(new retrofit2.Callback<AnalyticsResponse>() {
            @Override
            public void onResponse(retrofit2.Call<AnalyticsResponse> call, retrofit2.Response<AnalyticsResponse> response) {
                if (response.isSuccessful() && response.body() != null && response.body().totals != null) {
                    double month = response.body().totals.month;
                    double halfYear = response.body().totals.half_year;
                    double avgHalfYear = halfYear / 6.0;

                    TextView monthView = findViewById(R.id.stat_month_value);
                    if (monthView != null) {
                        monthView.setText(formatMoney(month, "RUB"));
                    }

                    TextView economyView = findViewById(R.id.stat_economy_value);
                    if (economyView != null) {
                        if (avgHalfYear > 0) {
                            double percent = ((avgHalfYear - month) / avgHalfYear) * 100.0;
                            if (percent < 0) percent = 0;
                            economyView.setText(String.format(Locale.getDefault(), "%.0f%%", percent));
                        } else {
                            economyView.setText("—");
                        }
                    }
                }
            }

            @Override
            public void onFailure(retrofit2.Call<AnalyticsResponse> call, Throwable t) { }
        });
    }

    private String formatMoney(double amount, String currency) {
        String cur = (currency == null || currency.isEmpty()) ? "RUB" : currency;
        String symbol = "RUB".equalsIgnoreCase(cur) ? "₽" : cur;
        return moneyFormat.format(amount) + " " + symbol;
    }

    private void openEditProfileSheet() {
        SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        String token = prefs.getString(KEY_TOKEN, null);
        if (token == null || token.isEmpty()) {
            startActivity(new Intent(this, AuthActivity.class));
            finish();
            return;
        }

        BottomSheetDialog dialog = new BottomSheetDialog(this);
        View view = LayoutInflater.from(this).inflate(R.layout.bottomsheet_edit_profile, null);

        EditText email = view.findViewById(R.id.edit_email);
        EditText phone = view.findViewById(R.id.edit_phone);
        TextView btnCancel = view.findViewById(R.id.btn_cancel);
        TextView btnSave = view.findViewById(R.id.btn_save);

        if (email != null) email.setText(currentEmail);
        if (phone != null) phone.setText(currentPhone);

        btnCancel.setOnClickListener(v -> dialog.dismiss());

        btnSave.setOnClickListener(v -> {
            String newEmail = email.getText().toString().trim();
            String newPhone = phone.getText().toString().trim();

            AuthApi authApi = ApiClient.getRetrofit().create(AuthApi.class);
            ProfileUpdateRequest request = new ProfileUpdateRequest(
                    newEmail.isEmpty() ? null : newEmail,
                    newPhone.isEmpty() ? null : newPhone
            );

            authApi.updateMe("Bearer " + token, request).enqueue(new retrofit2.Callback<UserOut>() {
                @Override
                public void onResponse(retrofit2.Call<UserOut> call, retrofit2.Response<UserOut> response) {
                    if (response.isSuccessful() && response.body() != null) {
                        currentEmail = response.body().email == null ? "" : response.body().email;
                        currentPhone = response.body().phone == null ? "" : response.body().phone;
                        TextView emailView = findViewById(R.id.profile_email);
                        if (emailView != null) {
                            emailView.setText(currentEmail);
                        }
                        TextView avatar = findViewById(R.id.profile_avatar_letter);
                        if (avatar != null && !currentEmail.isEmpty()) {
                            avatar.setText(currentEmail.substring(0, 1).toUpperCase());
                        }
                        dialog.dismiss();
                    } else {
                        Toast.makeText(ProfileActivity.this, "Не удалось сохранить", Toast.LENGTH_SHORT).show();
                    }
                }

                @Override
                public void onFailure(retrofit2.Call<UserOut> call, Throwable t) {
                    Toast.makeText(ProfileActivity.this, "Ошибка сети", Toast.LENGTH_SHORT).show();
                }
            });
        });

        dialog.setContentView(view);
        dialog.show();
    }

    private void openChangePasswordSheet() {
        SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        String token = prefs.getString(KEY_TOKEN, null);
        if (token == null || token.isEmpty()) {
            startActivity(new Intent(this, AuthActivity.class));
            finish();
            return;
        }

        BottomSheetDialog dialog = new BottomSheetDialog(this);
        View view = LayoutInflater.from(this).inflate(R.layout.bottomsheet_change_password, null);

        EditText current = view.findViewById(R.id.edit_current_password);
        EditText next = view.findViewById(R.id.edit_new_password);
        EditText repeat = view.findViewById(R.id.edit_new_password_repeat);
        TextView btnCancel = view.findViewById(R.id.btn_cancel);
        TextView btnSave = view.findViewById(R.id.btn_save);

        btnCancel.setOnClickListener(v -> dialog.dismiss());

        btnSave.setOnClickListener(v -> {
            String currentValue = current.getText().toString();
            String nextValue = next.getText().toString();
            String repeatValue = repeat.getText().toString();

            if (currentValue.isEmpty() || nextValue.isEmpty() || repeatValue.isEmpty()) {
                Toast.makeText(ProfileActivity.this, "Заполните все поля", Toast.LENGTH_SHORT).show();
                return;
            }

            if (!nextValue.equals(repeatValue)) {
                Toast.makeText(ProfileActivity.this, "Пароли не совпадают", Toast.LENGTH_SHORT).show();
                return;
            }

            AuthApi authApi = ApiClient.getRetrofit().create(AuthApi.class);
            PasswordChangeRequest request = new PasswordChangeRequest(currentValue, nextValue);
            authApi.changePassword("Bearer " + token, request).enqueue(new retrofit2.Callback<Void>() {
                @Override
                public void onResponse(retrofit2.Call<Void> call, retrofit2.Response<Void> response) {
                    if (response.isSuccessful()) {
                        dialog.dismiss();
                        Toast.makeText(ProfileActivity.this, "Пароль обновлён", Toast.LENGTH_SHORT).show();
                    } else {
                        Toast.makeText(ProfileActivity.this, "Не удалось сменить пароль", Toast.LENGTH_SHORT).show();
                    }
                }

                @Override
                public void onFailure(retrofit2.Call<Void> call, Throwable t) {
                    Toast.makeText(ProfileActivity.this, "Ошибка сети", Toast.LENGTH_SHORT).show();
                }
            });
        });

        dialog.setContentView(view);
        dialog.show();
    }

    private void openEmailImportSheet() {
        SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        String token = prefs.getString(KEY_TOKEN, null);
        if (token == null || token.isEmpty()) {
            startActivity(new Intent(this, AuthActivity.class));
            finish();
            return;
        }

        BottomSheetDialog dialog = new BottomSheetDialog(this);
        View view = LayoutInflater.from(this).inflate(R.layout.bottomsheet_email_import, null);

        TextView btnClose = view.findViewById(R.id.btn_close);
        TextView btnImport = view.findViewById(R.id.btn_import);
        Switch demoSwitch = view.findViewById(R.id.switch_demo);
        Switch consentSwitch = view.findViewById(R.id.switch_consent);

        EditText email = view.findViewById(R.id.edit_email);
        EditText password = view.findViewById(R.id.edit_password);
        EditText imap = view.findViewById(R.id.edit_imap);
        EditText mailbox = view.findViewById(R.id.edit_mailbox);
        RadioGroup providerGroup = view.findViewById(R.id.provider_group);

        TextView limitValue = view.findViewById(R.id.limit_value);
        View btnMinus = view.findViewById(R.id.btn_limit_minus);
        View btnPlus = view.findViewById(R.id.btn_limit_plus);

        View emailBlock = view.findViewById(R.id.email_block);
        View imapBlock = view.findViewById(R.id.imap_block);

        if (imap != null) imap.setText("imap.gmail.com");
        if (mailbox != null) mailbox.setText("INBOX");

        final int[] limit = {20};
        if (limitValue != null) {
            limitValue.setText(String.valueOf(limit[0]));
        }

        btnMinus.setOnClickListener(v -> {
            if (limit[0] > 1) {
                limit[0]--;
                limitValue.setText(String.valueOf(limit[0]));
            }
        });
        btnPlus.setOnClickListener(v -> {
            if (limit[0] < 200) {
                limit[0]++;
                limitValue.setText(String.valueOf(limit[0]));
            }
        });

        Runnable updateFields = () -> {
            boolean enabled = !demoSwitch.isChecked();
            float alpha = enabled ? 1f : 0.5f;

            if (emailBlock != null) emailBlock.setAlpha(alpha);
            if (imapBlock != null) imapBlock.setAlpha(alpha);

            if (email != null) email.setEnabled(enabled);
            if (password != null) password.setEnabled(enabled);
            if (imap != null) imap.setEnabled(enabled);
            if (mailbox != null) mailbox.setEnabled(enabled);
            if (consentSwitch != null) consentSwitch.setEnabled(enabled);
            if (!enabled && consentSwitch != null) consentSwitch.setChecked(false);
        };

        if (demoSwitch != null) {
            demoSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> updateFields.run());
        }
        updateFields.run();

        if (providerGroup != null && imap != null) {
            providerGroup.setOnCheckedChangeListener((group, checkedId) -> {
                if (checkedId == R.id.provider_gmail) {
                    imap.setText("imap.gmail.com");
                } else if (checkedId == R.id.provider_mailru) {
                    imap.setText("imap.mail.ru");
                } else if (checkedId == R.id.provider_yandex) {
                    imap.setText("imap.yandex.ru");
                } else if (checkedId == R.id.provider_outlook) {
                    imap.setText("imap-mail.outlook.com");
                }
            });
        }

        btnClose.setOnClickListener(v -> dialog.dismiss());

        btnImport.setOnClickListener(v -> {
            boolean useSample = demoSwitch != null && demoSwitch.isChecked();
            String emailValue = email == null ? "" : email.getText().toString().trim();
            String passwordValue = password == null ? "" : password.getText().toString();
            String imapValue = imap == null ? "" : imap.getText().toString().trim();
            String mailboxValue = mailbox == null ? "" : mailbox.getText().toString().trim();
            boolean consent = consentSwitch != null && consentSwitch.isChecked();

            if (!useSample) {
                if (emailValue.isEmpty() || passwordValue.isEmpty()) {
                    Toast.makeText(ProfileActivity.this, "Введите email и пароль", Toast.LENGTH_SHORT).show();
                    return;
                }
                if (!consent) {
                    Toast.makeText(ProfileActivity.this, "Нужно согласие на использование пароля", Toast.LENGTH_SHORT).show();
                    return;
                }
            }

            if (imapValue.isEmpty()) imapValue = "imap.gmail.com";
            if (mailboxValue.isEmpty()) mailboxValue = "INBOX";

            EmailImportRequest request = new EmailImportRequest(
                    useSample ? null : emailValue,
                    useSample ? null : passwordValue,
                    imapValue,
                    mailboxValue,
                    limit[0],
                    useSample,
                    consent
            );

            EmailApi api = ApiClient.getRetrofit().create(EmailApi.class);
            api.importEmails("Bearer " + token, request).enqueue(new retrofit2.Callback<EmailImportResult>() {
                @Override
                public void onResponse(retrofit2.Call<EmailImportResult> call, retrofit2.Response<EmailImportResult> response) {
                    if (response.isSuccessful() && response.body() != null) {
                        int created = response.body().created;
                        Toast.makeText(ProfileActivity.this, "Создано подписок: " + created, Toast.LENGTH_SHORT).show();
                        dialog.dismiss();
                    } else {
                        Toast.makeText(ProfileActivity.this, "Ошибка импорта: " + response.code(), Toast.LENGTH_SHORT).show();
                    }
                }

                @Override
                public void onFailure(retrofit2.Call<EmailImportResult> call, Throwable t) {
                    Toast.makeText(ProfileActivity.this, "Ошибка сети", Toast.LENGTH_SHORT).show();
                }
            });
        });

        dialog.setContentView(view);
        dialog.show();
    }
    private void openNotificationsBottomSheet() {
        SharedPreferences prefs = getSharedPreferences("auth_prefs", MODE_PRIVATE);
        String token = prefs.getString("access_token", null);
        if (token == null || token.isEmpty()) {
            startActivity(new Intent(this, AuthActivity.class));
            finish();
            return;
        }

        NotificationsApi api = ApiClient.getRetrofit().create(NotificationsApi.class);

        api.upcoming("Bearer " + token, 3).enqueue(new retrofit2.Callback<UpcomingNotificationsResponse>() {
            @Override
            public void onResponse(retrofit2.Call<UpcomingNotificationsResponse> call,
                                   retrofit2.Response<UpcomingNotificationsResponse> response) {
                if (!response.isSuccessful() || response.body() == null) {
                    Toast.makeText(getApplicationContext(), "Ошибка загрузки", Toast.LENGTH_SHORT).show();
                    return;
                }

                BottomSheetDialog dialog = new BottomSheetDialog(ProfileActivity.this);
                View view = LayoutInflater.from(ProfileActivity.this)
                        .inflate(R.layout.bottomsheet_upcoming_notifications, null);

                LinearLayout container = view.findViewById(R.id.bs_notifications_container);

                if (response.body().items == null || response.body().items.isEmpty()) {
                    TextView empty = new TextView(ProfileActivity.this);
                    empty.setText("Нет списаний в ближайшие 3 дня");
                    empty.setTextColor(getColor(R.color.text_secondary));
                    empty.setTextSize(12);
                    container.addView(empty);
                } else {
                    for (UpcomingNotificationItem item : response.body().items) {
                        View row = LayoutInflater.from(ProfileActivity.this)
                                .inflate(R.layout.item_calendar_payment, container, false);

                        TextView icon = row.findViewById(R.id.pay_icon_text);
                        TextView name = row.findViewById(R.id.pay_name);
                        TextView subtitle = row.findViewById(R.id.pay_subtitle);
                        TextView amount = row.findViewById(R.id.pay_amount);
                        TextView date = row.findViewById(R.id.pay_date);

                        String first = item.name != null && item.name.length() > 0 ? item.name.substring(0,1).toUpperCase() : "?";
                        icon.setText(first);
                        name.setText(item.name);

                        int d = item.days_until;
                        subtitle.setText(d == 0 ? "Сегодня" : (d == 1 ? "Завтра" : ("Через " + d + " дн.")));

                        amount.setText(item.amount + " " + (item.currency == null ? "RUB" : item.currency));
                        date.setText(item.next_billing_date == null ? "—" : item.next_billing_date);

                        container.addView(row);
                    }
                }

                dialog.setContentView(view);
                dialog.show();
            }

            @Override
            public void onFailure(retrofit2.Call<UpcomingNotificationsResponse> call, Throwable t) {
                Toast.makeText(getApplicationContext(), "Ошибка сети", Toast.LENGTH_SHORT).show();
            }
        });
    }
}
