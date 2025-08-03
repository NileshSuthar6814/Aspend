package org.x.aspend.ns

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.d(TAG, "Boot completed or package replaced")

                // Start the transaction detection service if enabled
                // This will be handled by the Flutter app when it starts
                try {
                    // You can add logic here to check if auto-detection is enabled
                    // and start the service accordingly
                    Log.d(TAG, "Boot receiver completed")
                } catch (e: Exception) {
                    Log.e(TAG, "Error in boot receiver: ${e.message}")
                }
            }
        }
    }
} 