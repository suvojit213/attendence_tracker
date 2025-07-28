package com.suvojeet.attendance_tracker

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import android.content.Intent
import androidx.core.content.FileProvider
import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.provider.Settings
import android.widget.Toast

class MainActivity : FlutterActivity() {
    private val REPORTS_CHANNEL = "com.suvojeet.attendance_tracker/reports"
    private val UPDATE_CHANNEL = "com.suvojeet.attendance_tracker/updater"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Reports Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, REPORTS_CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "saveFileToDocuments") {
                val fileName = call.argument<String>("fileName")
                val fileBytes = call.argument<ByteArray>("fileBytes")
                if (fileName != null && fileBytes != null) {
                    try {
                        val filePath = saveFileToDocuments(fileName, fileBytes)
                        result.success(filePath)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Could not save file: ${e.message}", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENTS", "File name or bytes are missing", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // Update Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "downloadAndInstall") {
                val url = call.argument<String>("url")
                if (url != null) {
                    AppUpdater(this).downloadAndInstall(url)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Download URL is missing", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveFileToDocuments(fileName: String, fileBytes: ByteArray): String? {
        val mimeType = when {
            fileName.endsWith(".pdf") -> "application/pdf"
            fileName.endsWith(".csv") -> "text/csv"
            else -> "application/octet-stream"
        }

        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOCUMENTS)
            }
        }

        val resolver = contentResolver
        var uri: Uri? = null
        try {
            uri = resolver.insert(MediaStore.Files.getContentUri("external"), contentValues)
            if (uri == null) {
                throw IOException("Failed to create new MediaStore record.")
            }
            resolver.openOutputStream(uri)?.use { outputStream ->
                outputStream.write(fileBytes)
            }
            return uri.toString()
        } catch (e: IOException) {
            uri?.let { orphanUri ->
                // Don't leave an orphan entry in the MediaStore
                resolver.delete(orphanUri, null, null)
            }
            throw e
        }
    }
}