package com.ctrls;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.GridLayout;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.ctrls.api.dto.UpcomingNotificationItem;
import com.ctrls.api.dto.UpcomingNotificationsResponse;
import com.google.android.material.bottomnavigation.BottomNavigationView;

import com.ctrls.api.ApiClient;
import com.ctrls.api.NotificationsApi;
import com.ctrls.api.SubscriptionsApi;
import com.ctrls.api.dto.SubscriptionOut;

import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

import com.google.android.material.bottomsheet.BottomSheetDialog;

public class CalendarActivity extends AppCompatActivity {
    private static final String PREFS = "auth_prefs";
    private static final String KEY_TOKEN = "access_token";

    private final SimpleDateFormat apiDate = new SimpleDateFormat("yyyy-MM-dd", Locale.US);
    private final SimpleDateFormat monthTitleFormat = new SimpleDateFormat("LLLL yyyy", new Locale("ru", "RU"));
    private final SimpleDateFormat dayTitleFormat = new SimpleDateFormat("d MMM", new Locale("ru", "RU"));
    private final DecimalFormat moneyFormat = new DecimalFormat("#,###.##");

    private final List<SubscriptionOut> allSubs = new ArrayList<>();
    private final Map<String, List<SubscriptionOut>> paymentsByDate = new HashMap<>();
    private final Calendar currentMonth = Calendar.getInstance();

    private SubscriptionsApi subscriptionsApi;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_calendar);
        View bell = findViewById(R.id.notification);
        if (bell != null) {
            bell.setOnClickListener(v -> openNotificationsBottomSheet());
        }
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.calendar_root), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, 0);

            View content = findViewById(R.id.calendar_scroll);
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

        BottomNavigationView nav = findViewById(R.id.bottom_nav);
        nav.setSelectedItemId(R.id.nav_calendar);

        nav.setOnItemSelectedListener(item -> {
            int id = item.getItemId();
            if (id == R.id.nav_home) {
                startActivity(new Intent(this, MainPageActivity.class));
                finish();
                return true;
            }

            if (id == R.id.nav_subs) {
                startActivity(new Intent(this, SubscriptionActivity.class));
                finish();
                return true;
            }

            if (id == R.id.nav_calendar) {
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

        currentMonth.set(Calendar.DAY_OF_MONTH, 1);
        currentMonth.set(Calendar.HOUR_OF_DAY, 0);
        currentMonth.set(Calendar.MINUTE, 0);
        currentMonth.set(Calendar.SECOND, 0);
        currentMonth.set(Calendar.MILLISECOND, 0);

        findViewById(R.id.month_prev).setOnClickListener(v -> {
            currentMonth.add(Calendar.MONTH, -1);
            renderMonth();
            renderSummary();
        });

        findViewById(R.id.month_next).setOnClickListener(v -> {
            currentMonth.add(Calendar.MONTH, 1);
            renderMonth();
            renderSummary();
        });

        loadSubscriptions();
    }

    private void loadSubscriptions() {
        SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        String token = prefs.getString(KEY_TOKEN, null);
        if (token == null || token.isEmpty()) {
            startActivity(new Intent(this, AuthActivity.class));
            finish();
            return;
        }

        subscriptionsApi.list("Bearer " + token).enqueue(new Callback<List<SubscriptionOut>>() {
            @Override
            public void onResponse(Call<List<SubscriptionOut>> call, Response<List<SubscriptionOut>> response) {
                if (response.code() == 401) {
                    prefs.edit().remove(KEY_TOKEN).apply();
                    startActivity(new Intent(CalendarActivity.this, AuthActivity.class));
                    finish();
                    return;
                }
                if (response.isSuccessful() && response.body() != null) {
                    allSubs.clear();
                    allSubs.addAll(response.body());
                    buildPaymentsIndex();
                    renderMonth();
                    renderSummary();
                    renderUpcoming7();
                } else {
                    Toast.makeText(CalendarActivity.this, "Ошибка загрузки подписок", Toast.LENGTH_SHORT).show();
                }
            }
            @Override
            public void onFailure(Call<List<SubscriptionOut>> call, Throwable t) {
                Toast.makeText(CalendarActivity.this, "Ошибка сети", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void buildPaymentsIndex() {
        paymentsByDate.clear();
        for (SubscriptionOut s : allSubs) {
            if (s.next_billing_date == null || s.next_billing_date.isEmpty()) continue;
            List<SubscriptionOut> list = paymentsByDate.get(s.next_billing_date);
            if (list == null) {
                list = new ArrayList<>();
                paymentsByDate.put(s.next_billing_date, list);
            }
            list.add(s);
        }
    }

    private void renderMonth() {
        TextView title = findViewById(R.id.month_title);
        String monthTitle = monthTitleFormat.format(currentMonth.getTime());
        monthTitle = capitalize(monthTitle);
        title.setText(monthTitle);

        GridLayout grid = findViewById(R.id.calendar_grid);
        grid.removeAllViews();
        if (grid.getWidth() == 0) {
            grid.post(this::renderMonth);
            return;
        }

        Calendar temp = (Calendar) currentMonth.clone();
        int daysInMonth = temp.getActualMaximum(Calendar.DAY_OF_MONTH);

        int dow = temp.get(Calendar.DAY_OF_WEEK);
        int offset = (dow + 5) % 7; // Monday=0 ... Sunday=6

        int cellMargin = dp(4);
        int cellSize = calculateCellSize(grid, cellMargin);
        for (int i = 0; i < offset; i++) {
            View empty = new View(this);
            GridLayout.LayoutParams lp = new GridLayout.LayoutParams();
            lp.width = 0;
            lp.height = cellSize;
            lp.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
            lp.setMargins(cellMargin, cellMargin, cellMargin, cellMargin);
            empty.setLayoutParams(lp);
            grid.addView(empty);
        }

        for (int day = 1; day <= daysInMonth; day++) {
            View item = LayoutInflater.from(this).inflate(R.layout.item_calendar_day, grid, false);
            TextView number = item.findViewById(R.id.day_number);
            View dot = item.findViewById(R.id.day_dot);
            FrameLayout container = item.findViewById(R.id.day_container);

            number.setText(String.valueOf(day));

            Calendar todayCal = Calendar.getInstance();
            todayCal = truncateTime(todayCal);

            Calendar cellDate = (Calendar) currentMonth.clone();
            cellDate.set(Calendar.DAY_OF_MONTH, day);
            cellDate = truncateTime(cellDate);

            boolean isToday =
                    cellDate.get(Calendar.YEAR) == todayCal.get(Calendar.YEAR)
                            && cellDate.get(Calendar.MONTH) == todayCal.get(Calendar.MONTH)
                            && cellDate.get(Calendar.DAY_OF_MONTH) == todayCal.get(Calendar.DAY_OF_MONTH);

            if (isToday) {
                container.setBackgroundResource(R.drawable.bg_calendar_day_today);
            }
            String key = dateKeyForDay(day);
            List<SubscriptionOut> list = paymentsByDate.get(key);
            if (list != null && !list.isEmpty()) {
                dot.setVisibility(View.VISIBLE);
                item.setOnClickListener(v -> showDayPaymentsBottomSheet(key, list));
            } else {
                dot.setVisibility(View.GONE);
            }

            GridLayout.LayoutParams lp = new GridLayout.LayoutParams();
            lp.width = 0;
            lp.height = cellSize;
            lp.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
            lp.setMargins(cellMargin, cellMargin, cellMargin, cellMargin);
            item.setLayoutParams(lp);
            grid.addView(item);
        }
    }

    private void renderSummary() {
        TextView totalValue = findViewById(R.id.summary_total_value);
        TextView countValue = findViewById(R.id.summary_payments_count);

        double total = 0;
        int count = 0;

        Calendar monthStart = (Calendar) currentMonth.clone();
        Calendar monthEnd = (Calendar) currentMonth.clone();
        monthEnd.set(Calendar.DAY_OF_MONTH, monthEnd.getActualMaximum(Calendar.DAY_OF_MONTH));

        for (SubscriptionOut s : allSubs) {
            Date next = parseDate(s.next_billing_date);
            if (next == null) continue;
            if (!next.before(monthStart.getTime()) && !next.after(monthEnd.getTime())) {
                total += s.amount;
                count++;
            }
        }

        totalValue.setText(formatMoney(total, "RUB"));
        countValue.setText(count + " платежей");
    }

    private void renderUpcoming7() {
        LinearLayout container = findViewById(R.id.upcoming_container);
        container.removeAllViews();

        Calendar today = truncateTime(Calendar.getInstance());
        Calendar end = (Calendar) today.clone();
        end.add(Calendar.DAY_OF_MONTH, 6);

        List<SubscriptionOut> upcoming = new ArrayList<>();
        for (SubscriptionOut s : allSubs) {
            Date next = parseDate(s.next_billing_date);
            if (next == null) continue;
            if (!next.before(today.getTime()) && !next.after(end.getTime())) {
                upcoming.add(s);
            }
        }

        upcoming.sort((a, b) -> {
            Date da = parseDate(a.next_billing_date);
            Date db = parseDate(b.next_billing_date);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return da.compareTo(db);
        });

        if (upcoming.isEmpty()) {
            TextView empty = new TextView(this);
            empty.setText("Нет платежей в ближайшие 7 дней");
            empty.setTextColor(getColor(R.color.text_secondary));
            empty.setTextSize(12);
            container.addView(empty);
            return;
        }

        for (SubscriptionOut s : upcoming) {
            View item = LayoutInflater.from(this).inflate(R.layout.item_calendar_payment, container, false);
            TextView icon = item.findViewById(R.id.pay_icon_text);
            TextView name = item.findViewById(R.id.pay_name);
            TextView subtitle = item.findViewById(R.id.pay_subtitle);
            TextView amount = item.findViewById(R.id.pay_amount);
            TextView date = item.findViewById(R.id.pay_date);

            String first = s.name != null && s.name.length() > 0 ? s.name.substring(0, 1).toUpperCase() : "?";
            icon.setText(first);
            name.setText(s.name);

            Date next = parseDate(s.next_billing_date);
            if (next != null) {
                int diff = daysBetween(today.getTime(), next);
                subtitle.setText(diff == 0 ? "Сегодня" : (diff == 1 ? "Завтра" : ("Через " + diff + " дн.")));
                date.setText(dayTitleFormat.format(next));
            } else {
                subtitle.setText("Дата неизвестна");
                date.setText("—");
            }

            amount.setText(formatMoney(s.amount, s.currency));
            container.addView(item);
        }
    }

    private String dateKeyForDay(int day) {
        Calendar c = (Calendar) currentMonth.clone();
        c.set(Calendar.DAY_OF_MONTH, day);
        return apiDate.format(c.getTime());
    }

    private Date parseDate(String dateStr) {
        if (dateStr == null || dateStr.isEmpty()) return null;
        try {
            return apiDate.parse(dateStr);
        } catch (Exception e) {
            return null;
        }
    }

    private Calendar truncateTime(Calendar cal) {
        cal.set(Calendar.HOUR_OF_DAY, 0);
        cal.set(Calendar.MINUTE, 0);
        cal.set(Calendar.SECOND, 0);
        cal.set(Calendar.MILLISECOND, 0);
        return cal;
    }

    private int daysBetween(Date start, Date end) {
        long diff = end.getTime() - start.getTime();
        return (int) (diff / (24L * 60L * 60L * 1000L));
    }

    private String formatMoney(double amount, String currency) {
        String cur = (currency == null || currency.isEmpty()) ? "RUB" : currency;
        String symbol = "RUB".equalsIgnoreCase(cur) ? "₽" : cur;
        return moneyFormat.format(amount) + " " + symbol;
    }

    private String capitalize(String text) {
        if (text == null || text.isEmpty()) return text;
        return text.substring(0, 1).toUpperCase() + text.substring(1);
    }

    private void showDayPaymentsBottomSheet(String dateKey, List<SubscriptionOut> list) {
        BottomSheetDialog dialog = new BottomSheetDialog(this);
        View view = LayoutInflater.from(this).inflate(R.layout.bottomsheet_day_payments, null);

        TextView title = view.findViewById(R.id.bs_day_title);
        LinearLayout container = view.findViewById(R.id.bs_payments_container);

        Date d = parseDate(dateKey);
        if (d != null) {
            title.setText(dayTitleFormat.format(d));
        }

        for (SubscriptionOut s : list) {
            View item = LayoutInflater.from(this).inflate(R.layout.item_calendar_payment, container, false);
            TextView icon = item.findViewById(R.id.pay_icon_text);
            TextView name = item.findViewById(R.id.pay_name);
            TextView subtitle = item.findViewById(R.id.pay_subtitle);
            TextView amount = item.findViewById(R.id.pay_amount);
            TextView date = item.findViewById(R.id.pay_date);

            String first = s.name != null && s.name.length() > 0 ? s.name.substring(0, 1).toUpperCase() : "?";
            icon.setText(first);
            name.setText(s.name);
            subtitle.setText("Списание в этот день");
            amount.setText(formatMoney(s.amount, s.currency));
            date.setText(dayTitleFormat.format(d));

            container.addView(item);
        }

        dialog.setContentView(view);
        dialog.show();
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    private int calculateCellSize(GridLayout grid, int marginPx) {
        int padding = grid.getPaddingLeft() + grid.getPaddingRight();
        int totalWidth = grid.getWidth() - padding;
        if (totalWidth <= 0) {
            return dp(44);
        }
        int size = (totalWidth - (marginPx * 2 * 7)) / 7;
        return Math.max(size, dp(36));
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

                BottomSheetDialog dialog = new BottomSheetDialog(CalendarActivity.this);
                View view = LayoutInflater.from(CalendarActivity.this)
                        .inflate(R.layout.bottomsheet_upcoming_notifications, null);

                LinearLayout container = view.findViewById(R.id.bs_notifications_container);

                if (response.body().items == null || response.body().items.isEmpty()) {
                    TextView empty = new TextView(CalendarActivity.this);
                    empty.setText("Нет списаний в ближайшие 3 дня");
                    empty.setTextColor(getColor(R.color.text_secondary));
                    empty.setTextSize(12);
                    container.addView(empty);
                } else {
                    for (UpcomingNotificationItem item : response.body().items) {
                        View row = LayoutInflater.from(CalendarActivity.this)
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
