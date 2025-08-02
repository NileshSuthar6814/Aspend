package org.x.aspend.ns

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings
import android.util.Log
import android.os.PowerManager
import android.net.Uri
import android.provider.Settings.System

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL_NAME = "transaction_detection"
    }

    private lateinit var channel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)

        // Set up method channel for native components
        TransactionDetectionService.setMethodChannel(channel)
        SmsReceiver.setMethodChannel(channel)

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestNotificationPermission" -> {
                    try {
                        val intent =
                            Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error requesting notification permission: ${e.message}")
                        result.error("PERMISSION_ERROR", e.message, null)
                    }
                }

                "checkNotificationPermission" -> {
                    try {
                        // Check if notification access is enabled
                        val enabled = isNotificationServiceEnabled()
                        result.success(enabled)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error checking notification permission: ${e.message}")
                        result.error("PERMISSION_CHECK_ERROR", e.message, null)
                    }
                }

                "requestBatteryOptimization" -> {
                    try {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                        intent.data = Uri.parse("package:$packageName")
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error requesting battery optimization: ${e.message}")
                        result.error("BATTERY_OPTIMIZATION_ERROR", e.message, null)
                    }
                }

                "startKeepAliveService" -> {
                    try {
                        KeepAliveService.startService(this)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error starting keep alive service: ${e.message}")
                        result.error("KEEP_ALIVE_ERROR", e.message, null)
                    }
                }

                "stopKeepAliveService" -> {
                    try {
                        KeepAliveService.stopService(this)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error stopping keep alive service: ${e.message}")
                        result.error("KEEP_ALIVE_ERROR", e.message, null)
                    }
                }

                "processNotification" -> {
                    try {
                        val title = call.argument<String>("title") ?: ""
                        val text = call.argument<String>("text") ?: ""
                        val bigText = call.argument<String>("bigText") ?: ""
                        val fullText = call.argument<String>("fullText") ?: ""
                        val packageName = call.argument<String>("packageName") ?: ""

                        Log.d(TAG, "Processing notification: $fullText")

                        // This will be handled by the Flutter side
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error processing notification: ${e.message}")
                        result.error("PROCESSING_ERROR", e.message, null)
                    }
                }

                "processSms" -> {
                    try {
                        val sender = call.argument<String>("sender") ?: ""
                        val body = call.argument<String>("body") ?: ""
                        val timestamp = call.argument<Long>("timestamp") ?: 0L

                        Log.d(TAG, "Processing SMS from $sender: $body")

                        // This will be handled by the Flutter side
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error processing SMS: ${e.message}")
                        result.error("SMS_PROCESSING_ERROR", e.message, null)
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        return flat?.contains(packageName) == true
    }

    override fun onResume() {
        super.onResume()
        // Start keep alive service when app resumes
        KeepAliveService.startService(this)

        // Handle widget intents
        handleWidgetIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle widget intents when app is already running
        handleWidgetIntent(intent)
    }

    private fun handleWidgetIntent(intent: Intent) {
        when (intent.action) {
            "ADD_INCOME" -> {
                Log.d(TAG, "Widget: Add Income clicked")
                // Send message to Flutter to show income dialog
                channel.invokeMethod("showAddIncomeDialog", null)
            }

            "ADD_EXPENSE" -> {
                Log.d(TAG, "Widget: Add Expense clicked")
                // Send message to Flutter to show expense dialog
                channel.invokeMethod("showAddExpenseDialog", null)
            }
        }
    }

    override fun onPause() {
        super.onPause()
        // Keep the service running even when app is paused
    }
}
