package com.example.attendance_tracker

import android.content.Intent
import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.attendance_tracker/email"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendEmail") {
                val to = call.argument<String>("to")
                val subject = call.argument<String>("subject")
                val body = call.argument<String>("body")
                if (to != null && subject != null && body != null) {
                    sendEmail(to, subject, body)
                    result.success(null)
                } else {
                    result.error("UNAVAILABLE", "Email details not provided.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun sendEmail(to: String, subject: String, body: String) {
        val intent = Intent(Intent.ACTION_SENDTO).apply {
            data = Uri.parse("mailto:")
            putExtra(Intent.EXTRA_EMAIL, arrayOf(to))
            putExtra(Intent.EXTRA_SUBJECT, subject)
            putExtra(Intent.EXTRA_TEXT, body)
        }
        if (intent.resolveActivity(packageManager) != null) {
            startActivity(intent)
        } else {
            // Optionally, handle the case where no email client is installed
        }
    }
}
