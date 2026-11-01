package com.geda.urjavatika.urja

import android.app.NotificationChannel
import android.app.NotificationManager
import android.Manifest
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.geda.urjavatika.urja/notifications"
    private val NOTIF_CHANNEL_ID = "urja_nudges"
    private val ACTION_CLAIM_DEPARTURE = "com.geda.urjavatika.urja.ACTION_CLAIM_DEPARTURE"
    private val ACTION_DISMISS = "com.geda.urjavatika.urja.ACTION_DISMISS"
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
                            2001,
                            "Turned Switch OFF (+5 🪙)"
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

    private val notificationActionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                ACTION_CLAIM_DEPARTURE -> {
                    val notifId = intent.getIntExtra("notif_id", 5001)
                    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    nm.cancel(notifId)
                    methodChannel?.invokeMethod("onDepartureRewardClaimed", mapOf("coins" to 10, "timestamp" to System.currentTimeMillis()))
                }
                ACTION_DISMISS -> {
                    val notifId = intent.getIntExtra("notif_id", 0)
                    if (notifId > 0) {
                        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        nm.cancel(notifId)
                    }
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        // Register power connected/disconnected broadcast receiver
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_POWER_DISCONNECTED)
            addAction(Intent.ACTION_POWER_CONNECTED)
        }
        registerReceiver(powerReceiver, filter)

        // Register action button receiver for modern notification actions
        val actionFilter = IntentFilter().apply {
            addAction(ACTION_CLAIM_DEPARTURE)
            addAction(ACTION_DISMISS)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(notificationActionReceiver, actionFilter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(notificationActionReceiver, actionFilter)
        }

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "Urja Reminder"
                    val message = call.argument<String>("message") ?: ""
                    val id = call.argument<Int>("id") ?: 1001
                    val actionButton = call.argument<String>("actionButton")
                    showNotification(title, message, id, actionButton)
                    result.success(true)
                }
                "triggerDepartureNotification" -> {
                    val distance = call.argument<Double>("distance") ?: 300.0
                    showDepartureNotification(distance.toInt())
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
                        2001,
                        "Turned Switch OFF (+5 🪙)"
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
                            3002,
                            "Run Clean Energy (+15 🪙)"
                        )
                    } else {
                        showNotification(
                            "💡 Phantom Vampire Load Alert",
                            "Your TV setup and AC in standby drain ~35W continuous power. Turn off the wall switch to save ~25 units/month (~₹155)!",
                            3001,
                            "Sweep Sockets (+10 🪙)"
                        )
                    }
                    result.success(true)
                }
                "requestPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val permission = Manifest.permission.POST_NOTIFICATIONS
                        if (checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED) {
                            requestPermissions(arrayOf(permission), 101)
                        }
                    }
                    result.success(true)
                }
                "requestLocationPermission" -> {
                    requestPermissions(
                        arrayOf(
                            android.Manifest.permission.ACCESS_FINE_LOCATION,
                            android.Manifest.permission.ACCESS_COARSE_LOCATION
                        ),
                        102
                    )
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
        try {
            unregisterReceiver(notificationActionReceiver)
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

    private fun showNotification(title: String, message: String, id: Int, actionButtonText: String? = null) {
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
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)

        if (!actionButtonText.isNullOrEmpty()) {
            val claimIntent = Intent(ACTION_CLAIM_DEPARTURE).apply {
                putExtra("notif_id", id)
            }
            val claimPendingIntent = PendingIntent.getBroadcast(
                this,
                id + 10,
                claimIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            builder.addAction(0, actionButtonText, claimPendingIntent)
        }

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(id, builder.build())
    }

    private fun showDepartureNotification(distanceMeters: Int) {
        val id = 5001
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val claimIntent = Intent(ACTION_CLAIM_DEPARTURE).apply {
            putExtra("notif_id", id)
        }
        val claimPendingIntent = PendingIntent.getBroadcast(
            this,
            id + 1,
            claimIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val dismissIntent = Intent(ACTION_DISMISS).apply {
            putExtra("notif_id", id)
        }
        val dismissPendingIntent = PendingIntent.getBroadcast(
            this,
            id + 2,
            dismissIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, NOTIF_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("⚡ Left Home (${distanceMeters}m)? Turn Off Wall Switches")
            .setContentText("Did you turn off the AC, water geyser & unplug phone chargers? Confirm to prevent continuous vampire drain and earn rewards!")
            .setStyle(
                NotificationCompat.BigTextStyle().bigText(
                    "You are ${distanceMeters}m away from home. Did you turn off the AC, geyser & unplug phone chargers? Avoid phantom vampire drain (~1.2 kg CO₂e). Tap Claim below to confirm and credit Urja Mudra coins!"
                )
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .addAction(0, "⚡ Claim +10 🪙 (All OFF)", claimPendingIntent)
            .addAction(0, "Dismiss", dismissPendingIntent)

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(id, builder.build())
    }
}
