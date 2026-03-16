package com.ctrls;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.google.android.material.bottomnavigation.BottomNavigationView;

import android.content.SharedPreferences;
import android.view.LayoutInflater;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.ctrls.api.ApiClient;
import com.ctrls.api.SubscriptionsApi;
import com.ctrls.api.dto.SubscriptionOut;

import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Date;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

import android.app.DatePickerDialog;
import android.widget.Switch;

import androidx.appcompat.app.AlertDialog;

import com.ctrls.api.dto.SubscriptionCreateRequest;
import com.google.android.material.bottomsheet.BottomSheetDialog;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Locale;

public class MainPageActivity extends AppCompatActivity {

    private static final String PREFS = "auth_prefs";
    private static final String KEY_TOKEN = "access_token";

    private SubscriptionsApi subscriptionsApi;
    private final SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd", Locale.US);
    private final SimpleDateFormat uiDate = new SimpleDateFormat("d MMMM", new Locale("ru", "RU"));
    private final SimpleDateFormat apiDate = new SimpleDateFormat("yyyy-MM-dd", Locale.US);
    private final DecimalFormat moneyFormat = new DecimalFormat("#,###.##");

    private List<SubscriptionOut> allSubscriptions = new ArrayList<>();
    private boolean showAllPayments = false;
    private static final int PERIOD_MONTH = 1;
    private static final int PERIOD_HALF_YEAR = 6;
    private static final int PERIOD_YEAR = 12;
    private int currentPeriodMonths = PERIOD_MONTH;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main_page);

        subscriptionsApi = ApiClient.getRetrofit().create(SubscriptionsApi.class);

        TextView toggle = findViewById(R.id.payments_toggle);
        toggle.setOnClickListener(v -> {
            showAllPayments = !showAllPayments;
            renderPayments();
        });

        View addButton = findViewById(R.id.add_subscription_button);
        if (addButton != null) {
            addButton.setOnClickListener(v -> openAddSubscriptionSheet());
        }

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main_page_root), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());

            v.setPadding(systemBars.left, systemBars.top, systemBars.right, 0);

            View content = findViewById(R.id.content_scroll);
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
        nav.setSelectedItemId(R.id.nav_home);

        nav.setOnItemSelectedListener(item -> {
            int id = item.getItemId();
            if (id == R.id.nav_home) {
                return true;
            }
            if (id == R.id.nav_subs) {
                startActivity(new Intent(this, SubscriptionActivity.class));
                finish();
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

        TextView monthTitle = findViewById(R.id.month_title);

        com.google.android.material.button.MaterialButtonToggleGroup periodToggle =
                findViewById(R.id.period_toggle);

        periodToggle.check(R.id.period_month);

        findViewById(R.id.period_month).setOnClickListener(v -> {
            currentPeriodMonths = PERIOD_MONTH;
            monthTitle.setText("Прогноз за месяц");
            renderStats();
        });

        findViewById(R.id.period_half_year).setOnClickListener(v -> {
            currentPeriodMonths = PERIOD_HALF_YEAR;
            monthTitle.setText("Прогноз за полгода");
            renderStats();
        });

        findViewById(R.id.period_year).setOnClickListener(v -> {
            currentPeriodMonths = PERIOD_YEAR;
            monthTitle.setText("Прогноз за год");
            renderStats();
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
                    startActivity(new Intent(MainPageActivity.this, AuthActivity.class));
                    finish();
                    return;
                }
                if (response.isSuccessful() && response.body() != null) {
                    allSubscriptions = response.body();
                    renderStats();
                    renderPayments();
                } else {
                    Toast.makeText(MainPageActivity.this, "Ошибка загрузки подписок", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<List<SubscriptionOut>> call, Throwable t) {
                Toast.makeText(MainPageActivity.this, "Ошибка сети", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void renderStats() {
        TextView totalMonth = findViewById(R.id.total_month_value);
        TextView activeCount = findViewById(R.id.active_count_value);
        TextView subsCount = findViewById(R.id.subscriptions_count_value);
        TextView nearestDays = findViewById(R.id.nearest_days_value);

        double monthlySum = 0;
        int active = 0;

        Date today = truncateTime(new Date());

        List<SubscriptionOut> upcoming = new ArrayList<>();
        double totalForPeriod = 0;

        for (SubscriptionOut s : allSubscriptions) {
            if ("monthly".equalsIgnoreCase(s.billing_period)) {
                totalForPeriod += s.amount * currentPeriodMonths;
            } else if ("yearly".equalsIgnoreCase(s.billing_period)) {
                totalForPeriod += s.amount * (currentPeriodMonths / 12.0);
            } else if ("weekly".equalsIgnoreCase(s.billing_period)) {
                double weeks = currentPeriodMonths * 4.345;
                totalForPeriod += s.amount * weeks;
            }

            Date next = parseDate(s.next_billing_date);
            if (next != null && !next.before(today)) {
                active++;
                upcoming.add(s);
            }
        }


        subsCount.setText(String.valueOf(allSubscriptions.size()));
        activeCount.setText(String.valueOf(active));
        totalMonth.setText(formatMoney(totalForPeriod, "RUB"));

        Integer nearest = getNearestDays(upcoming, today);
        nearestDays.setText(nearest == null ? "—" : (nearest == 0 ? "Сегодня" : ("Через " + nearest + " дн.")));
    }

    private void renderPayments() {
        LinearLayout container = findViewById(R.id.payments_container);
        TextView toggle = findViewById(R.id.payments_toggle);

        container.removeAllViews();

        Date today = truncateTime(new Date());

        List<SubscriptionOut> upcoming = new ArrayList<>();
        for (SubscriptionOut s : allSubscriptions) {
            Date next = parseDate(s.next_billing_date);
            if (next != null && !next.before(today)) {
                upcoming.add(s);
            }
        }

        Collections.sort(upcoming, (a, b) -> {
            Date da = parseDate(a.next_billing_date);
            Date db = parseDate(b.next_billing_date);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return da.compareTo(db);
        });

        int limit = showAllPayments ? upcoming.size() : Math.min(3, upcoming.size());
        for (int i = 0; i < limit; i++) {
            SubscriptionOut s = upcoming.get(i);
            View item = LayoutInflater.from(this).inflate(R.layout.item_payment, container, false);

            TextView iconText = item.findViewById(R.id.payment_icon_text);
            TextView name = item.findViewById(R.id.payment_name);
            TextView subtitle = item.findViewById(R.id.payment_subtitle);
            TextView amount = item.findViewById(R.id.payment_amount);

            String first = s.name != null && s.name.length() > 0 ? s.name.substring(0, 1).toUpperCase() : "?";
            iconText.setText(first);

            name.setText(s.name);

            Date next = parseDate(s.next_billing_date);
            Integer days = next == null ? null : daysBetween(today, next);
            if (days == null) {
                subtitle.setText("Дата неизвестна");
            } else if (days == 0) {
                subtitle.setText("Сегодня");
            } else {
                subtitle.setText("Через " + days + " дн.");
            }

            amount.setText(formatMoney(s.amount, s.currency));
            container.addView(item);
        }

        if (upcoming.size() <= 3) {
            toggle.setVisibility(View.GONE);
        } else {
            toggle.setVisibility(View.VISIBLE);
            toggle.setText(showAllPayments ? "Свернуть" : "Показать все");
        }
        renderSoonCharge();
        renderCategories();
    }



    private Date parseDate(String dateStr) {
        if (dateStr == null || dateStr.isEmpty()) return null;
        try {
            return dateFormat.parse(dateStr);
        } catch (Exception e) {
            return null;
        }
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

    private Integer getNearestDays(List<SubscriptionOut> list, Date today) {
        Integer min = null;
        for (SubscriptionOut s : list) {
            Date next = parseDate(s.next_billing_date);
            if (next == null || next.before(today)) continue;
            int d = daysBetween(today, next);
            if (min == null || d < min) min = d;
        }
        return min;
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

    private void renderSoonCharge() {
        View block = findViewById(R.id.soon_charge_block);
        TextView title = findViewById(R.id.soon_charge_title);
        TextView text = findViewById(R.id.soon_charge_text);

        Date today = truncateTime(new Date());

        SubscriptionOut nearest = null;
        int nearestDays = Integer.MAX_VALUE;

        for (SubscriptionOut s : allSubscriptions) {
            Date next = parseDate(s.next_billing_date);
            if (next == null || next.before(today)) continue;
            int days = daysBetween(today, next);
            if (days < nearestDays) {
                nearestDays = days;
                nearest = s;
            }
        }

        if (nearest == null) {
            block.setVisibility(View.GONE);
            return;
        }

        block.setVisibility(View.VISIBLE);
        title.setText("Скоро списание");

        String when;
        if (nearestDays == 0) {
            when = "Сегодня";
        } else {
            when = "Через " + nearestDays + " дн.";
        }

        String amount = formatMoney(nearest.amount, nearest.currency);
        text.setText(when + " будет списано " + amount + " за " + nearest.name);
    }

    private void renderCategories() {
        LinearLayout container = findViewById(R.id.categories_container);
        container.removeAllViews();

        java.util.HashMap<String, Integer> counts = new java.util.HashMap<>();
        for (SubscriptionOut s : allSubscriptions) {
            String key = (s.category == null || s.category.trim().isEmpty())
                    ? "Без категории"
                    : s.category.trim();
            counts.put(key, counts.getOrDefault(key, 0) + 1);
        }

        List<java.util.Map.Entry<String, Integer>> list = new ArrayList<>(counts.entrySet());
        Collections.sort(list, (a, b) -> b.getValue() - a.getValue());

        int limit = Math.min(4, list.size());

        for (int i = 0; i < limit; i++) {
            java.util.Map.Entry<String, Integer> entry = list.get(i);

            View item = LayoutInflater.from(this).inflate(R.layout.item_category, container, false);

            TextView count = item.findViewById(R.id.category_count);
            TextView name = item.findViewById(R.id.category_name);

            count.setText(String.valueOf(entry.getValue()));
            name.setText(entry.getKey());

            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                    0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f);
            if (i < limit - 1) {
                lp.setMarginEnd(10);
            }
            item.setLayoutParams(lp);

            container.addView(item);
        }
    }
    private void openAddSubscriptionSheet() {
        BottomSheetDialog dialog = new BottomSheetDialog(this);
        View view = LayoutInflater.from(this).inflate(R.layout.bottomsheet_add_subscription, null);

        EditText name = view.findViewById(R.id.sub_name);
        EditText category = view.findViewById(R.id.sub_category);
        EditText amount = view.findViewById(R.id.sub_amount);

        TextView currencyView = view.findViewById(R.id.sub_currency);
        TextView periodView = view.findViewById(R.id.sub_period);

        TextView dateValue = view.findViewById(R.id.sub_date_value);
        Switch dateSwitch = view.findViewById(R.id.sub_date_switch);

        TextView btnCancel = view.findViewById(R.id.btn_cancel);
        TextView btnSave = view.findViewById(R.id.btn_save);

        String[] currency = new String[] {"RUB"};
        String[] period = new String[] {"monthly"};

        Calendar selectedDate = Calendar.getInstance();
        dateValue.setText("Указать дату");
        dateValue.setEnabled(false);
        dateValue.setAlpha(0.6f);

        currencyView.setOnClickListener(v -> {
            String[] options = {"RUB", "USD", "EUR"};
            new AlertDialog.Builder(this)
                    .setTitle("Валюта")
                    .setItems(options, (d, which) -> {
                        currency[0] = options[which];
                        currencyView.setText(options[which]);
                    })
                    .show();
        });

        periodView.setOnClickListener(v -> {
            String[] labels = {"Ежемесячно", "Раз в 6 месяцев", "Ежегодно"};
            String[] values = {"monthly", "half_year", "yearly"};
            new AlertDialog.Builder(this)
                    .setTitle("Период")
                    .setItems(labels, (d, which) -> {
                        period[0] = values[which];
                        periodView.setText(labels[which]);
                    })
                    .show();
        });

        dateSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            dateValue.setEnabled(isChecked);
            dateValue.setAlpha(isChecked ? 1f : 0.6f);
            if (!isChecked) {
                dateValue.setText("Указать дату");
            } else {
                dateValue.setText(uiDate.format(selectedDate.getTime()));
            }
        });

        dateValue.setOnClickListener(v -> {
            if (!dateSwitch.isChecked()) return;
            DatePickerDialog picker = new DatePickerDialog(
                    this,
                    (dp, y, m, d) -> {
                        selectedDate.set(Calendar.YEAR, y);
                        selectedDate.set(Calendar.MONTH, m);
                        selectedDate.set(Calendar.DAY_OF_MONTH, d);
                        dateValue.setText(uiDate.format(selectedDate.getTime()));
                    },
                    selectedDate.get(Calendar.YEAR),
                    selectedDate.get(Calendar.MONTH),
                    selectedDate.get(Calendar.DAY_OF_MONTH)
            );
            picker.show();
        });

        btnCancel.setOnClickListener(v -> dialog.dismiss());

        btnSave.setOnClickListener(v -> {
            String n = name.getText().toString().trim();
            String c = category.getText().toString().trim();
            String aStr = amount.getText().toString().trim();

            if (n.isEmpty() || aStr.isEmpty()) {
                Toast.makeText(this, "Заполните название и сумму", Toast.LENGTH_SHORT).show();
                return;
            }

            double a = Double.parseDouble(aStr);
            String nextDate = dateSwitch.isChecked() ? apiDate.format(selectedDate.getTime()) : null;

            String token = getSharedPreferences(PREFS, MODE_PRIVATE)
                    .getString(KEY_TOKEN, null);

            if (token == null || token.isEmpty()) {
                startActivity(new Intent(this, AuthActivity.class));
                finish();
                return;
            }

            SubscriptionCreateRequest req = new SubscriptionCreateRequest(
                    n,
                    a,
                    currency[0],
                    period[0],
                    c.isEmpty() ? null : c,
                    nextDate
            );

            subscriptionsApi.create("Bearer " + token, req).enqueue(new Callback<SubscriptionOut>() {
                @Override
                public void onResponse(Call<SubscriptionOut> call, Response<SubscriptionOut> response) {
                    if (response.isSuccessful()) {
                        dialog.dismiss();
                        loadSubscriptions();
                    } else {
                        Toast.makeText(MainPageActivity.this, "Ошибка сохранения", Toast.LENGTH_SHORT).show();
                    }
                }

                @Override
                public void onFailure(Call<SubscriptionOut> call, Throwable t) {
                    Toast.makeText(MainPageActivity.this, "Ошибка сети", Toast.LENGTH_SHORT).show();
                }
            });
        });

        dialog.setContentView(view);
        dialog.show();
    }

}
