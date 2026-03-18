package com.ctrls.workers;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

import com.ctrls.R;
import com.ctrls.api.ApiClient;
import com.ctrls.api.NotificationsApi;
import com.ctrls.api.dto.UpcomingNotificationsResponse;

import retrofit2.Response;

public class UpcomingNotificationsWorker extends Worker {
    private static final String CHANNEL_ID = "upcoming_payments";

    public UpcomingNotificationsWorker(@NonNull Context context, @NonNull WorkerParameters params) {
        super(context, params);
    }

    @NonNull
    @Override
    public Result doWork() {
        SharedPreferences prefs = getApplicationContext().getSharedPreferences("auth_prefs", Context.MODE_PRIVATE);
        String token = prefs.getString("access_token", null);
        if (token == null || token.isEmpty()) return Result.success();

        try {
            NotificationsApi api = ApiClient.getRetrofit().create(NotificationsApi.class);
            Response<UpcomingNotificationsResponse> response =
                    api.upcoming("Bearer " + token, 3).execute();

            if (!response.isSuccessful() || response.body() == null || response.body().items == null) {
                return Result.success();
            }

            int count = response.body().items.size();
            if (count == 0) return Result.success();

            NotificationManager manager = (NotificationManager) getApplicationContext()
                    .getSystemService(Context.NOTIFICATION_SERVICE);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                NotificationChannel channel = new NotificationChannel(
                        CHANNEL_ID,
                        "Upcoming payments",
                        NotificationManager.IMPORTANCE_DEFAULT
                );
                manager.createNotificationChannel(channel);
            }

            String text = "Списаний в ближайшие 3 дня: " + count;

            NotificationCompat.Builder builder = new NotificationCompat.Builder(getApplicationContext(), CHANNEL_ID)
                    .setSmallIcon(R.drawable.ic_bell)
                    .setContentTitle("Ближайшие списания")
                    .setContentText(text)
                    .setAutoCancel(true);

            manager.notify(1001, builder.build());
            return Result.success();
        } catch (Exception e) {
            return Result.retry();
        }
    }
}
