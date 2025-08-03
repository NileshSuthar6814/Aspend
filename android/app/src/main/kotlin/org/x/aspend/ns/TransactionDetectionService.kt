package org.x.aspend.ns

import android.app.Notification
import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.MethodChannel

class TransactionDetectionService : NotificationListenerService() {
    companion object {
        private const val TAG = "TransactionDetection"
        private const val CHANNEL_NAME = "transaction_detection"

        private var methodChannel: MethodChannel? = null

        fun setMethodChannel(channel: MethodChannel) {
            methodChannel = channel
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "TransactionDetectionService created")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        super.onNotificationPosted(sbn)

        try {
            val notification = sbn.notification
            val extras = notification.extras

            val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
            val text = extras.getString(Notification.EXTRA_TEXT) ?: ""
            val bigText = extras.getString(Notification.EXTRA_BIG_TEXT) ?: ""

            val fullText = "$title $text $bigText".trim()

            Log.d(TAG, "Notification received: $fullText")

            // Send to Flutter for processing
            methodChannel?.invokeMethod(
                "onNotificationReceived", mapOf(
                    "title" to title,
                    "text" to text,
                    "bigText" to bigText,
                    "fullText" to fullText,
                    "packageName" to sbn.packageName
                )
            )

        } catch (e: Exception) {
            Log.e(TAG, "Error processing notification: ${e.message}")
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        super.onNotificationRemoved(sbn)
        // We don't need to handle removed notifications for transaction detection
    }
} 