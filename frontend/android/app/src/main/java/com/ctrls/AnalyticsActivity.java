package com.ctrls;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.ctrls.api.AnalyticsApi;
import com.ctrls.api.ApiClient;
import com.ctrls.api.NotificationsApi;
import com.ctrls.api.dto.UpcomingNotificationItem;
import com.ctrls.api.dto.UpcomingNotificationsResponse;
import com.ctrls.api.dto.analytics.AnalyticsChartPoint;
import com.ctrls.api.dto.analytics.AnalyticsChartResponse;
import com.ctrls.api.dto.analytics.AnalyticsResponse;
import com.github.mikephil.charting.charts.LineChart;
import com.github.mikephil.charting.charts.PieChart;
import com.github.mikephil.charting.components.Description;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineData;
import com.github.mikephil.charting.data.LineDataSet;
import com.github.mikephil.charting.data.PieData;
import com.github.mikephil.charting.data.PieDataSet;
import com.github.mikephil.charting.data.PieEntry;
import com.github.mikephil.charting.formatter.IndexAxisValueFormatter;
import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.google.android.material.bottomsheet.BottomSheetDialog;
import com.google.android.material.button.MaterialButtonToggleGroup;

import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class AnalyticsActivity extends AppCompatActivity {
    private static final String PREFS = "auth_prefs";
    private static final String KEY_TOKEN = "access_token";

    private AnalyticsApi analyticsApi;

    private String currentPeriod = "month"; // month | half_year | year
    private String selectedCategory = null; // null = все

    private AnalyticsResponse cachedOverview;

    private final DecimalFormat moneyFormat = new DecimalFormat("#,###.##");

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_analytics);
        View bell = findViewById(R.id.notification);
        if (bell != null) {
            bell.setOnClickListener(v -> openNotificationsBottomSheet());
        }
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.analytics_root), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, 0);

            View content = findViewById(R.id.analytics_scroll);
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

        analyticsApi = ApiClient.getRetrofit().create(AnalyticsApi.class);

        MaterialButtonToggleGroup toggle = findViewById(R.id.analytics_period_toggle);
        toggle.check(R.id.analytics_period_month);

        findViewById(R.id.analytics_period_month).setOnClickListener(v -> {
            currentPeriod = "month";
            loadChart();
            updateCardsFromChart();
        });

        findViewById(R.id.analytics_period_half_year).setOnClickListener(v -> {
            currentPeriod = "half_year";
            loadChart();
            updateCardsFromChart();
        });

        findViewById(R.id.analytics_period_year).setOnClickListener(v -> {
            currentPeriod = "year";
            loadChart();
            updateCardsFromChart();
        });

        findViewById(R.id.category_selector).setOnClickListener(v -> openCategoryPicker());

        BottomNavigationView nav = findViewById(R.id.bottom_nav);
        nav.setSelectedItemId(R.id.nav_analytics);

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
                startActivity(new Intent(this, CalendarActivity.class));
                finish();
                return true;
            }
            if (id == R.id.nav_analytics) {
                return true;
            }
            if (id == R.id.nav_profile) {
                startActivity(new Intent(this, ProfileActivity.class));
                finish();
                return true;
            }
            return true;
        });

        loadOverview();
        loadChart();
    }

    private void loadOverview() {
        String token = getToken();
        if (token == null) return;

        analyticsApi.getAnalytics("Bearer " + token).enqueue(new Callback<AnalyticsResponse>() {
            @Override
            public void onResponse(Call<AnalyticsResponse> call, Response<AnalyticsResponse> response) {
                if (response.isSuccessful() && response.body() != null) {
                    cachedOverview = response.body();
                    renderPieChart();
                    updateCategoryList();
                    TextView error = findViewById(R.id.analytics_error);
                    error.setVisibility(View.GONE);

                } else {
                    showError();
                }
            }

            @Override
            public void onFailure(Call<AnalyticsResponse> call, Throwable t) {
                showError();
            }
        });
    }

    private void loadChart() {
        String token = getToken();
        if (token == null) return;

        analyticsApi.getChart("Bearer " + token, currentPeriod, selectedCategory).enqueue(new Callback<AnalyticsChartResponse>() {
            @Override
            public void onResponse(Call<AnalyticsChartResponse> call, Response<AnalyticsChartResponse> response) {
                if (response.isSuccessful() && response.body() != null) {
                    renderLineChart(response.body());
                    updateCardsFromSeries(response.body().series);
                    TextView error = findViewById(R.id.analytics_error);
                    error.setVisibility(View.GONE);

                } else {
                    showError();
                }
            }

            @Override
            public void onFailure(Call<AnalyticsChartResponse> call, Throwable t) {
                showError();
            }
        });
    }

    private void renderLineChart(AnalyticsChartResponse chart) {
        LineChart lineChart = findViewById(R.id.analytics_line_chart);

        List<Entry> entries = new ArrayList<>();
        List<String> labels = new ArrayList<>();
        if (chart.series != null) {
            for (int i = 0; i < chart.series.size(); i++) {
                AnalyticsChartPoint p = chart.series.get(i);
                entries.add(new Entry(i, (float) p.value));
                labels.add(p.label);
            }
        }

        LineDataSet dataSet = new LineDataSet(entries, "");
        dataSet.setColor(0xFF9D1AF4);
        dataSet.setCircleColor(0xFF9D1AF4);
        dataSet.setCircleRadius(4f);
        dataSet.setLineWidth(2f);
        dataSet.setDrawValues(false);

        LineData lineData = new LineData(dataSet);
        lineChart.setData(lineData);

        XAxis xAxis = lineChart.getXAxis();
        xAxis.setPosition(XAxis.XAxisPosition.BOTTOM);
        xAxis.setDrawGridLines(false);
        xAxis.setValueFormatter(new IndexAxisValueFormatter(labels));
        xAxis.setGranularity(1f);

        lineChart.getAxisRight().setEnabled(false);
        lineChart.getAxisLeft().setDrawGridLines(true);
        Description desc = new Description();
        desc.setText("");
        lineChart.setDescription(desc);
        lineChart.getLegend().setEnabled(false);
        lineChart.invalidate();
    }

    private void renderPieChart() {
        PieChart pieChart = findViewById(R.id.analytics_pie_chart);

        List<PieEntry> entries = new ArrayList<>();
        if (cachedOverview != null && cachedOverview.by_category != null) {
            for (Map.Entry<String, Double> e : cachedOverview.by_category.entrySet()) {
                entries.add(new PieEntry(e.getValue().floatValue(), e.getKey()));
            }
        }

        PieDataSet dataSet = new PieDataSet(entries, "");
        dataSet.setSliceSpace(2f);
        dataSet.setColors(
                0xFF8A2BE2,
                0xFFEC407A,
                0xFFFFA000,
                0xFF00C853,
                0xFF42A5F5
        );
        PieData data = new PieData(dataSet);
        data.setDrawValues(true);
        pieChart.setData(data);
        pieChart.getDescription().setEnabled(false);
        pieChart.getLegend().setEnabled(false);
        pieChart.invalidate();
    }

    private void updateCategoryList() {
        LinearLayout list = findViewById(R.id.analytics_category_list);
        list.removeAllViews();

        if (cachedOverview == null || cachedOverview.by_category == null) return;

        for (Map.Entry<String, Double> e : cachedOverview.by_category.entrySet()) {
            TextView row = new TextView(this);
            row.setText(e.getKey() + "  " + formatMoney(e.getValue(), "RUB"));
            row.setTextColor(getColor(R.color.text_primary));
            row.setTextSize(12);
            list.addView(row);
        }
    }

    private void updateCardsFromSeries(List<AnalyticsChartPoint> series) {
        TextView avg = findViewById(R.id.avg_spend_value);
        TextView trend = findViewById(R.id.trend_value);
        TextView savings = findViewById(R.id.savings_value);
        TextView efficiency = findViewById(R.id.efficiency_value);
        TextView minValue = findViewById(R.id.analytics_min_value);
        TextView maxValue = findViewById(R.id.analytics_max_value);

        if (series == null || series.isEmpty()) {
            avg.setText("—");
            trend.setText("—");
            savings.setText("—");
            efficiency.setText("—");
            minValue.setText("—");
            maxValue.setText("—");
            return;
        }

        double sum = 0;
        double min = Double.MAX_VALUE;
        double max = 0;
        for (AnalyticsChartPoint p : series) {
            sum += p.value;
            min = Math.min(min, p.value);
            max = Math.max(max, p.value);
        }
        double avgValue = sum / series.size();
        double first = series.get(0).value;
        double last = series.get(series.size() - 1).value;
        double trendPct = first > 0 ? ((last - first) / first) * 100.0 : 0;
        double savingsValue = max - min;
        double efficiencyValue = max > 0 ? (avgValue / max) * 100.0 : 0;

        avg.setText(formatMoney(avgValue, "RUB"));
        trend.setText(String.format(Locale.getDefault(), "%.1f%%", trendPct));
        savings.setText(formatMoney(savingsValue, "RUB"));
        efficiency.setText(String.format(Locale.getDefault(), "%.0f%%", efficiencyValue));
        minValue.setText(formatMoney(min, "RUB"));
        maxValue.setText(formatMoney(max, "RUB"));
    }

    private void updateCardsFromChart() {

        loadChart();
    }

    private void openCategoryPicker() {
        if (cachedOverview == null || cachedOverview.by_category == null) return;

        List<String> categories = new ArrayList<>(cachedOverview.by_category.keySet());
        categories.add(0, "Все категории");

        new AlertDialog.Builder(this)
                .setTitle("Категории")
                .setItems(categories.toArray(new String[0]), (d, which) -> {
                    String value = categories.get(which);
                    selectedCategory = value.equals("Все категории") ? null : value;
                    TextView cat = findViewById(R.id.analytics_category_value);
                    cat.setText(value);
                    loadChart();
                })
                .show();
    }

    private void showError() {
        TextView error = findViewById(R.id.analytics_error);
        error.setVisibility(View.VISIBLE);
    }

    private String getToken() {
        SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        String token = prefs.getString(KEY_TOKEN, null);
        if (token == null || token.isEmpty()) {
            startActivity(new Intent(this, AuthActivity.class));
            finish();
            return null;
        }
        return token;
    }

    private String formatMoney(double amount, String currency) {
        String cur = (currency == null || currency.isEmpty()) ? "RUB" : currency;
        String symbol = "RUB".equalsIgnoreCase(cur) ? "₽" : cur;
        return moneyFormat.format(amount) + " " + symbol;
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

                BottomSheetDialog dialog = new BottomSheetDialog(AnalyticsActivity.this);
                View view = LayoutInflater.from(AnalyticsActivity.this)
                        .inflate(R.layout.bottomsheet_upcoming_notifications, null);

                LinearLayout container = view.findViewById(R.id.bs_notifications_container);

                if (response.body().items == null || response.body().items.isEmpty()) {
                    TextView empty = new TextView(AnalyticsActivity.this);
                    empty.setText("Нет списаний в ближайшие 3 дня");
                    empty.setTextColor(getColor(R.color.text_secondary));
                    empty.setTextSize(12);
                    container.addView(empty);
                } else {
                    for (UpcomingNotificationItem item : response.body().items) {
                        View row = LayoutInflater.from(AnalyticsActivity.this)
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
