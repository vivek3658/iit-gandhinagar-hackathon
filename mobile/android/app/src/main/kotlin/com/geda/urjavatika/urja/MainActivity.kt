package com.geda.urjavatika.urja

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.geda.urjavatika.urja/notifications"
    private val NOTIF_CHANNEL_ID = "urja_nudges"
    private var methodChannel: MethodChannel? = null
    private var isChargerNudgeEnabled = true
    private var wasCharging = false

    private val powerReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_POWER_DISCONNECTED -> {
                    if (isChargerNudgeEnabled) {
                        showNotification(
                            "🔌 Charger Unplugged! Save Standby Power",
                            "Don't forget to turn off the switch at the wall socket! Idle chargers drain phantom vampire power 24/7.",
                            2001
                        )
                    }
                    methodChannel?.invokeMethod("onChargerDisconnected", mapOf("timestamp" to System.currentTimeMillis()))
                    wasCharging = false
                }
                Intent.ACTION_POWER_CONNECTED -> {
                    wasCharging = true
                    methodChannel?.invokeMethod("onChargerConnected", mapOf("timestamp" to System.currentTimeMillis()))
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        // Dynamically register power connected/disconnected broadcast receiver
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_POWER_DISCONNECTED)
            addAction(Intent.ACTION_POWER_CONNECTED)
        }
        registerReceiver(powerReceiver, filter)

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "Urja Reminder"
                    val message = call.argument<String>("message") ?: ""
                    val id = call.argument<Int>("id") ?: 1001
                    showNotification(title, message, id)
                    result.success(true)
                }
                "setChargerNudgeEnabled" -> {
                    isChargerNudgeEnabled = call.argument<Boolean>("enabled") ?: true
                    result.success(true)
                }
                "triggerChargerUnplugNudge" -> {
                    showNotification(
                        "🔌 Charger Unplugged! Save Standby Power",
                        "Don't forget to turn off the switch at the wall socket! Idle chargers drain phantom vampire power 24/7.",
                        2001
                    )
                    channel.invokeMethod("onChargerDisconnected", mapOf("timestamp" to System.currentTimeMillis()))
                    result.success(true)
                }
                "triggerLearningNotification" -> {
                    val type = call.argument<String>("type") ?: "phantom"
                    if (type == "solar") {
                        showNotification(
                            "☀️ Solar Peak Window (11 AM - 3 PM)",
                            "Prime solar generation is active! Run washing machines and water pumps now to utilize 100% clean rooftop sun power.",
                            3002
                        )
                    } else {
                        showNotification(
                            "💡 Phantom Vampire Load Alert",
                            "Your TV setup and AC in standby drain ~35W continuous power. Turn off the wall switch to save ~25 units/month (~₹155)!",
                            3001
                        )
                    }
                    result.success(true)
                }
                "requestPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 101)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(powerReceiver)
        } catch (_: Exception) {}
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "URJA Life Nudges"
            val descriptionText = "Real-time energy conservation and charger notifications"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(NOTIF_CHANNEL_ID, name, importance).apply {
                description = descriptionText
                enableVibration(true)
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showNotification(title: String, message: String, id: Int) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, NOTIF_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(id, builder.build())
    }
}
