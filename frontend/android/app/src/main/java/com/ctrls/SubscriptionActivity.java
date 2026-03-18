package com.ctrls;

import android.app.DatePickerDialog;
import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.ctrls.api.dto.UpcomingNotificationItem;
import com.ctrls.api.dto.UpcomingNotificationsResponse;
import com.google.android.material.bottomnavigation.BottomNavigationView;

import android.content.SharedPreferences;
import android.text.Editable;
import android.text.TextWatcher;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.CheckBox;
import android.widget.TextView;
import android.widget.ImageView;
import android.widget.Toast;

import androidx.appcompat.app.AlertDialog;

import com.ctrls.api.ApiClient;
import com.ctrls.api.SubscriptionsApi;
import com.ctrls.api.NotificationsApi;
import com.ctrls.api.dto.SubscriptionOut;
import com.ctrls.api.dto.SubscriptionUpdateRequest;
import com.google.android.material.bottomsheet.BottomSheetDialog;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class SubscriptionActivity extends AppCompatActivity {

    private static final String PREFS = "auth_prefs";
    private static final String KEY_TOKEN = "access_token";

    private SubscriptionsApi subscriptionsApi;

    private final SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd", Locale.US);
    private final SimpleDateFormat viewDate = new SimpleDateFormat("d MMM", new Locale("ru", "RU"));

    private final List<SubscriptionOut> allSubs = new ArrayList<>();
    private final List<SubscriptionOut> filteredSubs = new ArrayList<>();

    private String searchQuery = "";
    private int currentTab = 0;

    private final Set<String> categoryFilter = new HashSet<>();
    private final Set<String> periodFilter = new HashSet<>();
    private Double minPrice = null;
    private Double maxPrice = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_subscription);
        View bell = findViewById(R.id.notification);
        if (bell != null) {
            bell.setOnClickListener(v -> openNotificationsBottomSheet());
        }
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.subscription_root), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());

            v.setPadding(systemBars.left, systemBars.top, systemBars.right, 0);

            View content = findViewById(R.id.subscription_scroll);
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

        subscriptionsApi = ApiClient.getRetrofit().create(SubscriptionsApi.class);

        EditText search = findViewById(R.id.search_input);
        search.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) {}
            @Override public void afterTextChanged(Editable s) {
                searchQuery = s.toString().trim().toLowerCase();
                applyFilters();
            }
        });

        findViewById(R.id.filter_button).setOnClickListener(v -> openFiltersDialog());

        findViewById(R.id.chip_all).setOnClickListener(v -> setTab(0));
        findViewById(R.id.chip_active).setOnClickListener(v -> setTab(1));
        findViewById(R.id.chip_paused).setOnClickListener(v -> setTab(2));

        loadSubscriptions();

        BottomNavigationView nav = findViewById(R.id.bottom_nav);
        nav.setSelectedItemId(R.id.nav_subs);

        nav.setOnItemSelectedListener(item -> {
            int id = item.getItemId();
            if (id == R.id.nav_home) {
                startActivity(new Intent(this, MainPageActivity.class));
                finish();
                return true;
            }
            if (id == R.id.nav_subs) {
                return true;
            }

            if (id == R.id.nav_calendar) {
                startActivity(new Intent(this, CalendarActivity.class));
                finish();
                return true;
            }

            if (id == R.id.nav_analytics) {
                startActivity(new Intent(this, AnalyticsActivity.class));
                finish();
                return true;
            }

            if (id == R.id.nav_profile) {
                startActivity(new Intent(this, ProfileActivity.class));
                finish();
                return true;
            }
            return true;
        });
    }

    private void loadSubscriptions() {
        String token = getTokenOrRedirect();
        if (token == null) return;

        subscriptionsApi.list("Bearer " + token).enqueue(new Callback<List<SubscriptionOut>>() {
            @Override
            public void onResponse(Call<List<SubscriptionOut>> call, Response<List<SubscriptionOut>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    allSubs.clear();
                    allSubs.addAll(response.body());
                    updateChips();
                    applyFilters();
                }
            }

            @Override
            public void onFailure(Call<List<SubscriptionOut>> call, Throwable t) { }
        });
    }

    private void setTab(int tab) {
        currentTab = tab;
        updateChips();
        applyFilters();
    }

    private void updateChips() {
        int all = allSubs.size();
        int active = 0;
        int paused = 0;
        Date today = truncateTime(new Date());

        for (SubscriptionOut s : allSubs) {
            if (isActive(s, today)) active++;
            else paused++;
        }

        TextView chipAll = findViewById(R.id.chip_all);
        TextView chipActive = findViewById(R.id.chip_active);
        TextView chipPaused = findViewById(R.id.chip_paused);

        chipAll.setText("Все (" + all + ")");
        chipActive.setText("Активные (" + active + ")");
        chipPaused.setText("На паузе (" + paused + ")");

        chipAll.setBackgroundResource(currentTab == 0 ? R.drawable.bg_chip_active : R.drawable.bg_chip);
        chipAll.setTextColor(getColor(currentTab == 0 ? android.R.color.white : R.color.text_primary));

        chipActive.setBackgroundResource(currentTab == 1 ? R.drawable.bg_chip_active : R.drawable.bg_chip);
        chipActive.setTextColor(getColor(currentTab == 1 ? android.R.color.white : R.color.text_primary));

        chipPaused.setBackgroundResource(currentTab == 2 ? R.drawable.bg_chip_active : R.drawable.bg_chip);
        chipPaused.setTextColor(getColor(currentTab == 2 ? android.R.color.white : R.color.text_primary));
    }

    private void applyFilters() {
        filteredSubs.clear();
        Date today = truncateTime(new Date());

        for (SubscriptionOut s : allSubs) {
            boolean isActive = isActive(s, today);
            if (currentTab == 1 && !isActive) continue;
            if (currentTab == 2 && isActive) continue;

            if (!searchQuery.isEmpty() && (s.name == null || !s.name.toLowerCase().contains(searchQuery))) {
                continue;
            }

            if (!categoryFilter.isEmpty()) {
                String cat = s.category == null ? "" : s.category.trim();
                if (!categoryFilter.contains(cat)) continue;
            }

            if (!periodFilter.isEmpty()) {
                String p = s.billing_period == null ? "" : s.billing_period.toLowerCase();
                if (!periodFilter.contains(p)) continue;
            }

            if (minPrice != null && s.amount < minPrice) continue;
            if (maxPrice != null && s.amount > maxPrice) continue;

            filteredSubs.add(s);
        }

        renderList();
    }

    private void renderList() {
        LinearLayout container = findViewById(R.id.subscriptions_container);
        container.removeAllViews();

        Date today = truncateTime(new Date());

        for (SubscriptionOut s : filteredSubs) {
            View item = LayoutInflater.from(this).inflate(R.layout.item_subscription, container, false);

            TextView icon = item.findViewById(R.id.sub_icon_text);
            TextView name = item.findViewById(R.id.sub_name);
            TextView status = item.findViewById(R.id.sub_status);
            TextView info = item.findViewById(R.id.sub_info);
            TextView price = item.findViewById(R.id.sub_price);
            TextView date = item.findViewById(R.id.sub_date);

            String first = s.name != null && s.name.length() > 0 ? s.name.substring(0,1).toUpperCase() : "?";
            icon.setText(first);

            name.setText(s.name);

            Date next = parseDate(s.next_billing_date);
            boolean isActive = isActive(s, today);
            status.setText(isActive ? "Активна" : "На паузе");
            status.setBackgroundResource(isActive ? R.drawable.bg_status_active : R.drawable.bg_soft_purple);
            status.setTextColor(isActive ? getColor(R.color.text_primary) : getColor(R.color.primary_purple));

            info.setText(s.category == null ? "Без категории" : s.category);

            price.setText(formatMoney(s.amount, s.currency));

            if (next != null) {
                date.setText(viewDate.format(next));
            } else {
                date.setText("—");
            }

            ImageView menu = item.findViewById(R.id.sub_menu);
            if (menu != null) {
                menu.setOnClickListener(v -> showActionsDialog(s));
            }

            container.addView(item);
        }
    }

    private void openFiltersDialog() {
        View view = LayoutInflater.from(this).inflate(R.layout.dialog_filters, null);

        LinearLayout catContainer = view.findViewById(R.id.filter_categories_container);

        Set<String> cats = new HashSet<>();
        for (SubscriptionOut s : allSubs) {
            if (s.category != null && !s.category.trim().isEmpty()) {
                cats.add(s.category.trim());
            }
        }

        for (String c : cats) {
            CheckBox cb = new CheckBox(this);
            cb.setText(c);
            cb.setChecked(categoryFilter.contains(c));
            catContainer.addView(cb);
        }

        CheckBox pm = view.findViewById(R.id.filter_period_monthly);
        CheckBox pw = view.findViewById(R.id.filter_period_weekly);
        CheckBox py = view.findViewById(R.id.filter_period_yearly);

        pm.setChecked(periodFilter.contains("monthly"));
        pw.setChecked(periodFilter.contains("weekly"));
        py.setChecked(periodFilter.contains("yearly"));

        EditText min = view.findViewById(R.id.filter_price_min);
        EditText max = view.findViewById(R.id.filter_price_max);

        if (minPrice != null) min.setText(String.valueOf(minPrice));
        if (maxPrice != null) max.setText(String.valueOf(maxPrice));

        new AlertDialog.Builder(this)
                .setTitle("Фильтр")
                .setView(view)
                .setPositiveButton("Применить", (d, w) -> {
                    categoryFilter.clear();
                    for (int i = 0; i < catContainer.getChildCount(); i++) {
                        View child = catContainer.getChildAt(i);
                        if (child instanceof CheckBox) {
                            CheckBox cb = (CheckBox) child;
                            if (cb.isChecked()) categoryFilter.add(cb.getText().toString());
                        }
                    }

                    periodFilter.clear();
                    if (pm.isChecked()) periodFilter.add("monthly");
                    if (pw.isChecked()) periodFilter.add("weekly");
                    if (py.isChecked()) periodFilter.add("yearly");

                    minPrice = min.getText().toString().trim().isEmpty() ? null : Double.parseDouble(min.getText().toString());
                    maxPrice = max.getText().toString().trim().isEmpty() ? null : Double.parseDouble(max.getText().toString());

                    applyFilters();
                })
                .setNegativeButton("Сбросить", (d, w) -> {
                    categoryFilter.clear();
                    periodFilter.clear();
                    minPrice = null;
                    maxPrice = null;
                    applyFilters();
                })
                .show();
    }

    private Date parseDate(String dateStr) {
        if (dateStr == null || dateStr.isEmpty()) return null;
        try { return dateFormat.parse(dateStr); } catch (Exception e) { return null; }
    }

    private Date truncateTime(Date date) {
        Calendar cal = Calendar.getInstance();
        cal.setTime(date);
        cal.set(Calendar.HOUR_OF_DAY, 0);
        cal.set(Calendar.MINUTE, 0);
        cal.set(Calendar.SECOND, 0);
        cal.set(Calendar.MILLISECOND, 0);
        return cal.getTime();
    }

    private String formatMoney(double amount, String currency) {
        String cur = (currency == null || currency.isEmpty()) ? "RUB" : currency;
        String symbol = "RUB".equalsIgnoreCase(cur) ? "₽" : cur;
        return amount + " " + symbol;
    }

    private void showActionsDialog(SubscriptionOut s) {
        String token = getTokenOrRedirect();
        if (token == null) return;

        View view = LayoutInflater.from(this).inflate(R.layout.dialog_subscription_actions, null);

        TextView icon = view.findViewById(R.id.dialog_sub_icon);
        TextView name = view.findViewById(R.id.dialog_sub_name);
        TextView status = view.findViewById(R.id.dialog_sub_status);
        TextView date = view.findViewById(R.id.dialog_sub_date);
        TextView category = view.findViewById(R.id.dialog_sub_category);
        TextView amount = view.findViewById(R.id.dialog_sub_amount);
        TextView nextDate = view.findViewById(R.id.dialog_sub_next_date);

        TextView actionPause = view.findViewById(R.id.action_pause);
        TextView actionDelete = view.findViewById(R.id.action_delete);

        String first = s.name != null && s.name.length() > 0 ? s.name.substring(0, 1).toUpperCase() : "?";
        icon.setText(first);
        name.setText(s.name);

        Date next = parseDate(s.next_billing_date);
        if (next != null) date.setText(viewDate.format(next));
        else date.setText("—");

        boolean paused = isPaused(s);
        status.setText(paused ? "На паузе" : "Активна");
        status.setBackgroundResource(paused ? R.drawable.bg_soft_purple : R.drawable.bg_status_active);
        status.setTextColor(paused ? getColor(R.color.primary_purple) : getColor(R.color.text_primary));

        category.setText("Категория: " + (s.category == null ? "Без категории" : s.category));
        amount.setText("Сумма: " + formatMoney(s.amount, s.currency));
        nextDate.setText("Следующее списание: " + (s.next_billing_date == null ? "—" : s.next_billing_date));

        actionPause.setText(paused ? "Возобновить" : "Поставить на паузу");

        AlertDialog dialog = new AlertDialog.Builder(this)
                .setView(view)
                .create();

        actionPause.setOnClickListener(v -> {
            dialog.dismiss();
            if (paused) {
                resumeSubscriptionWithDate(token, s.id);
            } else {
                pauseSubscription(token, s.id);
            }
        });

        actionDelete.setOnClickListener(v -> {
            dialog.dismiss();
            confirmDelete(token, s.id);
        });

        dialog.show();
    }

    private boolean isPaused(SubscriptionOut s) {
        Date next = parseDate(s.next_billing_date);
        Date today = truncateTime(new Date());
        return next == null || next.before(today);
    }

    private boolean isActive(SubscriptionOut s, Date today) {
        Date next = parseDate(s.next_billing_date);
        return next != null && !next.before(today);
    }

    private String getTokenOrRedirect() {
        SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        String token = prefs.getString(KEY_TOKEN, null);
        if (token == null || token.isEmpty()) {
            startActivity(new Intent(this, AuthActivity.class));
            finish();
            return null;
        }
        return token;
    }

    private void pauseSubscription(String token, int subscriptionId) {
        SubscriptionUpdateRequest request = new SubscriptionUpdateRequest(null); // пауза = null
        subscriptionsApi.update("Bearer " + token, subscriptionId, request)
                .enqueue(new Callback<SubscriptionOut>() {
                    @Override
                    public void onResponse(Call<SubscriptionOut> call, Response<SubscriptionOut> response) {
                        if (response.isSuccessful()) {
                            loadSubscriptions();
                        } else {
                            String body = "";
                            try {
                                if (response.errorBody() != null) {
                                    body = response.errorBody().string();
                                }
                            } catch (Exception ignored) { }

                            Toast.makeText(SubscriptionActivity.this,
                                    "Ошибка: " + response.code() + " " + body,
                                    Toast.LENGTH_LONG).show();
                        }
                    }

                    @Override
                    public void onFailure(Call<SubscriptionOut> call, Throwable t) {
                        Toast.makeText(SubscriptionActivity.this, "Ошибка сети", Toast.LENGTH_SHORT).show();
                    }
                });
    }

    private void resumeSubscriptionWithDate(String token, int subscriptionId) {
        Calendar selectedDate = Calendar.getInstance();

        DatePickerDialog picker = new DatePickerDialog(
                this,
                (dp, y, m, d) -> {
                    selectedDate.set(Calendar.YEAR, y);
                    selectedDate.set(Calendar.MONTH, m);
                    selectedDate.set(Calendar.DAY_OF_MONTH, d);

                    String nextDate = dateFormat.format(selectedDate.getTime());

                    SubscriptionUpdateRequest request = new SubscriptionUpdateRequest(nextDate);
                    subscriptionsApi.update("Bearer " + token, subscriptionId, request)
                            .enqueue(new Callback<SubscriptionOut>() {
                                @Override
                                public void onResponse(Call<SubscriptionOut> call, Response<SubscriptionOut> response) {
                                    if (response.isSuccessful()) {
                                        loadSubscriptions();
                                    } else {
                                        Toast.makeText(SubscriptionActivity.this, "Не удалось возобновить", Toast.LENGTH_SHORT).show();
                                    }
                                }

                                @Override
                                public void onFailure(Call<SubscriptionOut> call, Throwable t) {
                                    Toast.makeText(SubscriptionActivity.this, "Ошибка сети", Toast.LENGTH_SHORT).show();
                                }
                            });
                },
                selectedDate.get(Calendar.YEAR),
                selectedDate.get(Calendar.MONTH),
                selectedDate.get(Calendar.DAY_OF_MONTH)
        );

        picker.getDatePicker().setMinDate(System.currentTimeMillis());
        picker.show();
    }

    private void confirmDelete(String token, int subscriptionId) {
        new AlertDialog.Builder(this)
                .setTitle("Удалить подписку?")
                .setMessage("Подписка будет удалена полностью.")
                .setPositiveButton("Удалить", (d, w) -> deleteSubscription(token, subscriptionId))
                .setNegativeButton("Отмена", null)
                .show();
    }

    private void deleteSubscription(String token, int subscriptionId) {
        subscriptionsApi.delete("Bearer " + token, subscriptionId)
                .enqueue(new Callback<Void>() {
                    @Override
                    public void onResponse(Call<Void> call, Response<Void> response) {
                        if (response.isSuccessful()) {
                            loadSubscriptions();
                        } else {
                            Toast.makeText(SubscriptionActivity.this, "Не удалось удалить", Toast.LENGTH_SHORT).show();
                        }
                    }

                    @Override
                    public void onFailure(Call<Void> call, Throwable t) {
                        Toast.makeText(SubscriptionActivity.this, "Ошибка сети", Toast.LENGTH_SHORT).show();
                    }
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

                BottomSheetDialog dialog = new BottomSheetDialog(SubscriptionActivity.this);
                View view = LayoutInflater.from(SubscriptionActivity.this)
                        .inflate(R.layout.bottomsheet_upcoming_notifications, null);

                LinearLayout container = view.findViewById(R.id.bs_notifications_container);

                if (response.body().items == null || response.body().items.isEmpty()) {
                    TextView empty = new TextView(SubscriptionActivity.this);
                    empty.setText("Нет списаний в ближайшие 3 дня");
                    empty.setTextColor(getColor(R.color.text_secondary));
                    empty.setTextSize(12);
                    container.addView(empty);
                } else {
                    for (UpcomingNotificationItem item : response.body().items) {
                        View row = LayoutInflater.from(SubscriptionActivity.this)
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
