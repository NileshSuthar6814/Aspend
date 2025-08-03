package org.x.aspend.ns

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.telephony.SmsMessage
import android.util.Log
import io.flutter.plugin.common.MethodChannel

class SmsReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "SmsReceiver"
        private var methodChannel: MethodChannel? = null

        fun setMethodChannel(channel: MethodChannel) {
            methodChannel = channel
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            try {
                val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
                if (messages != null) {
                    for (message in messages) {
                        val sender = message.originatingAddress ?: ""
                        val body = message.messageBody ?: ""

                        Log.d(TAG, "SMS received from $sender: $body")

                        // Send to Flutter for processing
                        methodChannel?.invokeMethod(
                            "onSmsReceived", mapOf(
                                "sender" to sender,
                                "body" to body,
                                "timestamp" to message.timestampMillis
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error processing SMS: ${e.message}")
            }
        }
    }
} 