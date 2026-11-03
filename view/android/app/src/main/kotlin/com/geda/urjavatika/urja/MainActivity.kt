package com.geda.urjavatika.urja

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import java.security.MessageDigest
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class MainActivity : FlutterActivity() {
    private val secureChannelName = "urja/secure_store"
    private val discoveryChannelName = "urja/device_discovery"
    private val notificationsChannelName = "com.geda.urjavatika.urja/notifications"
    private val vaultAlias = "urja_refresh_token_v1"
    private val preferencesName = "urja_secure_session"
    private val notificationPreferencesName = "urja_notification_preferences"
    private val tokenKey = "refresh_token"
    private val ivKey = "refresh_token_iv"
    private val chargerNudgeKey = "charger_nudge_enabled"
    private val handler = Handler(Looper.getMainLooper())
    private val bleDevices = linkedMapOf<String, Map<String, Any?>>()
    private val mdnsDevices = linkedMapOf<String, Map<String, Any?>>()
    private val serviceListeners = mutableListOf<NsdManager.DiscoveryListener>()
    private var scanResult: MethodChannel.Result? = null
    private var permissionResult: MethodChannel.Result? = null
    private var notificationPermissionResult: MethodChannel.Result? = null
    private var bluetoothScanner: BluetoothLeScanner? = null
    private var powerReceiverRegistered = false

    private val powerReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != Intent.ACTION_POWER_DISCONNECTED) return
            if (!chargerNudgeEnabled()) return
            postChargerNudge()
        }
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val address = result.device.address ?: return
            val localId = MessageDigest.getInstance("SHA-256")
                .digest(address.toByteArray())
                .take(12)
                .joinToString("") { "%02x".format(it) }
            val advertisedName = result.scanRecord?.deviceName
            val deviceName = advertisedName
                ?: runCatching { result.device.name }.getOrNull()
                ?: "Bluetooth device"
            bleDevices[localId] = mapOf(
                "localId" to localId,
                "name" to deviceName.take(48),
                "method" to "BLE",
                "category" to "other",
            )
        }

        override fun onScanFailed(errorCode: Int) {
            finishScan("BLE scan failed ($errorCode).")
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, secureChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getRefreshToken" -> result.success(readRefreshToken())
                    "saveRefreshToken" -> {
                        val refreshToken = call.arguments as? String
                        if (refreshToken.isNullOrBlank()) {
                            result.error("invalid_token", "Refresh token is empty.", null)
                        } else {
                            runCatching { saveRefreshToken(refreshToken) }
                                .onSuccess { result.success(null) }
                                .onFailure {
                                    result.error("secure_store_failed", "Could not securely save the session.", null)
                                }
                        }
                    }
                    "clearRefreshToken" -> {
                        runCatching { clearRefreshToken() }
                            .onSuccess { result.success(null) }
                            .onFailure {
                                result.error("secure_store_failed", "Could not clear the saved session.", null)
                            }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, discoveryChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "discoverNearbyDevices") {
                    requestBluetoothPermissions(result)
                } else {
                    result.notImplemented()
                }
            }

        createNotificationChannel()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notificationsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getChargerNudgeEnabled" -> result.success(chargerNudgeEnabled())
                    "requestNotificationPermission" -> requestNotificationPermission(result)
                    "setChargerNudgeEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled")
                        if (enabled == null) {
                            result.error("invalid_argument", "A reminder setting is required.", null)
                        } else if (enabled && !canPostNotifications()) {
                            result.error(
                                "notifications_permission_required",
                                "Allow notifications before enabling charger reminders.",
                                null,
                            )
                        } else {
                            getSharedPreferences(notificationPreferencesName, Context.MODE_PRIVATE)
                                .edit()
                                .putBoolean(chargerNudgeKey, enabled)
                                .apply()
                            result.success(true)
                        }
                    }
                    "showChargerNudgeTest" -> {
                        if (!canPostNotifications()) {
                            result.error(
                                "notifications_permission_required",
                                "Allow notifications before sending a test reminder.",
                                null,
                            )
                        } else {
                            postChargerNudge()
                            result.success(true)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        if (!powerReceiverRegistered) {
            registerReceiver(powerReceiver, IntentFilter(Intent.ACTION_POWER_DISCONNECTED))
            powerReceiverRegistered = true
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            REQUEST_BLUETOOTH_PERMISSIONS -> {
                val result = permissionResult ?: return
                permissionResult = null
                if (grantResults.isNotEmpty() &&
                    grantResults.all { it == PackageManager.PERMISSION_GRANTED }
                ) {
                    beginDiscovery(result)
                } else {
                    result.error(
                        "permission_denied",
                        "Bluetooth permission is needed to scan nearby devices. You can still add a device manually.",
                        null,
                    )
                }
            }
            REQUEST_NOTIFICATION_PERMISSION -> {
                val result = notificationPermissionResult ?: return
                notificationPermissionResult = null
                result.success(canPostNotifications())
            }
        }
    }

    override fun onDestroy() {
        if (powerReceiverRegistered) {
            unregisterReceiver(powerReceiver)
            powerReceiverRegistered = false
        }
        super.onDestroy()
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(canPostNotifications())
            return
        }
        if (notificationPermissionResult != null) {
            result.error(
                "permission_request_in_progress",
                "A notification permission request is already in progress.",
                null,
            )
            return
        }
        notificationPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_NOTIFICATION_PERMISSION,
        )
    }

    private fun canPostNotifications(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N &&
            !manager.areNotificationsEnabled()
        ) {
            return false
        }
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
            manager.getNotificationChannel(NOTIFICATION_CHANNEL_ID)?.importance !=
            NotificationManager.IMPORTANCE_NONE
    }

    private fun chargerNudgeEnabled(): Boolean =
        getSharedPreferences(notificationPreferencesName, Context.MODE_PRIVATE)
            .getBoolean(chargerNudgeKey, false)

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            "Energy nudges",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Optional reminders for everyday energy-saving habits."
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun postChargerNudge() {
        if (!canPostNotifications()) return
        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this).setPriority(Notification.PRIORITY_DEFAULT)
        }
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Phone unplugged — one small energy check")
            .setContentText("Finished charging? Switch the wall socket off too.")
            .setStyle(
                Notification.BigTextStyle().bigText(
                    "If you’ve finished charging, switch the wall socket off too. Urja can’t tell whether the socket is still on.",
                ),
            )
            .setAutoCancel(true)
            .build()
        getSystemService(NotificationManager::class.java).notify(CHARGER_NUDGE_ID, notification)
    }

    private fun requestBluetoothPermissions(result: MethodChannel.Result) {
        if (scanResult != null || permissionResult != null) {
            result.error("scan_in_progress", "A device scan is already running.", null)
            return
        }
        val required = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            listOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT)
        } else {
            listOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }
        val missing = required.filter {
            checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isEmpty()) {
            beginDiscovery(result)
        } else {
            permissionResult = result
            requestPermissions(missing.toTypedArray(), REQUEST_BLUETOOTH_PERMISSIONS)
        }
    }

    private fun beginDiscovery(result: MethodChannel.Result) {
        scanResult = result
        bleDevices.clear()
        mdnsDevices.clear()
        startBleScan()
        startMdnsDiscovery()
        handler.postDelayed({ finishScan(null) }, SCAN_DURATION_MS)
    }

    private fun startBleScan() {
        val scanner = (getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)
            ?.adapter
            ?.bluetoothLeScanner
        bluetoothScanner = scanner
        if (scanner == null) return
        try {
            scanner.startScan(scanCallback)
        } catch (_: SecurityException) {
            finishScan("Bluetooth permission was revoked.")
        } catch (_: IllegalStateException) {
            finishScan("Bluetooth is unavailable. Try adding your device manually.")
        }
    }

    private fun startMdnsDiscovery() {
        val manager = getSystemService(Context.NSD_SERVICE) as? NsdManager ?: return
        val serviceTypes = listOf("_http._tcp.", "_googlecast._tcp.", "_airplay._tcp.")
        serviceTypes.forEach { serviceType ->
            val listener = object : NsdManager.DiscoveryListener {
                override fun onDiscoveryStarted(type: String) = Unit

                override fun onServiceFound(service: NsdServiceInfo) {
                    val identity = "${service.serviceType}:${service.serviceName}"
                    mdnsDevices[identity] = mapOf(
                        "localId" to identity,
                        "name" to service.serviceName.take(48),
                        "method" to "MDNS",
                        "category" to "other",
                    )
                }

                override fun onServiceLost(service: NsdServiceInfo) {
                    mdnsDevices.remove("${service.serviceType}:${service.serviceName}")
                }

                override fun onDiscoveryStopped(type: String) = Unit

                override fun onStartDiscoveryFailed(type: String, errorCode: Int) {
                    stopListener(this)
                }

                override fun onStopDiscoveryFailed(type: String, errorCode: Int) {
                    stopListener(this)
                }
            }
            serviceListeners.add(listener)
            runCatching {
                manager.discoverServices(serviceType, NsdManager.PROTOCOL_DNS_SD, listener)
            }.onFailure {
                serviceListeners.remove(listener)
            }
        }
    }

    private fun stopListener(listener: NsdManager.DiscoveryListener) {
        val manager = getSystemService(Context.NSD_SERVICE) as? NsdManager ?: return
        runCatching { manager.stopServiceDiscovery(listener) }
        serviceListeners.remove(listener)
    }

    private fun finishScan(error: String?) {
        val result = scanResult ?: return
        scanResult = null
        handler.removeCallbacksAndMessages(null)
        runCatching { bluetoothScanner?.stopScan(scanCallback) }
        serviceListeners.toList().forEach(::stopListener)
        if (error != null && bleDevices.isEmpty() && mdnsDevices.isEmpty()) {
            result.error("discovery_failed", error, null)
        } else {
            result.success((bleDevices.values + mdnsDevices.values).toList())
        }
    }

    private fun readRefreshToken(): String? {
        val preferences = getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val stored = preferences.getString(tokenKey, null) ?: return null
        val encodedIv = preferences.getString(ivKey, null) ?: return null
        return runCatching {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            val iv = Base64.decode(encodedIv, Base64.NO_WRAP)
            cipher.init(Cipher.DECRYPT_MODE, loadOrCreateKey(), GCMParameterSpec(128, iv))
            String(cipher.doFinal(Base64.decode(stored, Base64.NO_WRAP)), Charsets.UTF_8)
        }.getOrNull()
    }

    private fun saveRefreshToken(token: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, loadOrCreateKey())
        val encrypted = Base64.encodeToString(cipher.doFinal(token.toByteArray()), Base64.NO_WRAP)
        val encodedIv = Base64.encodeToString(cipher.iv, Base64.NO_WRAP)
        getSharedPreferences(preferencesName, Context.MODE_PRIVATE).edit()
            .putString(tokenKey, encrypted)
            .putString(ivKey, encodedIv)
            .apply()
    }

    private fun clearRefreshToken() {
        getSharedPreferences(preferencesName, Context.MODE_PRIVATE).edit()
            .remove(tokenKey)
            .remove(ivKey)
            .apply()
    }

    private fun loadOrCreateKey(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val existing = keyStore.getKey(vaultAlias, null)
        if (existing is SecretKey) return existing
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                vaultAlias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true)
                .build(),
        )
        return generator.generateKey()
    }

    companion object {
        private const val REQUEST_BLUETOOTH_PERMISSIONS = 17041
        private const val REQUEST_NOTIFICATION_PERMISSION = 17042
        private const val SCAN_DURATION_MS = 9_000L
        private const val NOTIFICATION_CHANNEL_ID = "urja_energy_nudges"
        private const val CHARGER_NUDGE_ID = 2201
    }
}
