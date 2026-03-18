package com.ctrls;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;

import com.ctrls.api.ApiClient;
import com.ctrls.api.NotificationsApi;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.ctrls.api.dto.UpcomingNotificationItem;
import com.ctrls.api.dto.UpcomingNotificationsResponse;
import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.google.android.material.bottomsheet.BottomSheetDialog;

import android.content.SharedPreferences;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

public class ProfileActivity extends AppCompatActivity {

    private static final String PREFS = "auth_prefs";
    private static final String KEY_TOKEN = "access_token";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_profile);
        View bell = findViewById(R.id.notification);
        if (bell != null) {
            bell.setOnClickListener(v -> openNotificationsBottomSheet());
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
