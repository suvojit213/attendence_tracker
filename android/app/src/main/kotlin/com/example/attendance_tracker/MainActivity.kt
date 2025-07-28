package com.example.attendance_tracker

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

import androidx.biometric.BiometricPrompt
import androidx.biometric.BiometricManager
import java.util.concurrent.Executor
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val REPORTS_CHANNEL = "com.example.attendance_tracker/reports"
    private val BIOMETRIC_CHANNEL = "com.example.attendance_tracker/biometric"

    private lateinit var executor: Executor
    private lateinit var biometricPrompt: BiometricPrompt
    private lateinit var promptInfo: BiometricPrompt.PromptInfo

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

        // Biometric Method Channel
        executor = Executors.newSingleThreadExecutor()

        promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Biometric login for Attendance Tracker")
            .setSubtitle("Log in using your biometric credential")
            .setNegativeButtonText("Use account password")
            .build()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BIOMETRIC_CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "authenticate" -> {
                    authenticateWithBiometrics(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun authenticateWithBiometrics(result: MethodChannel.Result) {
        val biometricManager = BiometricManager.from(this)
        when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL)) {
            BiometricManager.BIOMETRIC_SUCCESS -> {
                // App can authenticate using biometrics
                biometricPrompt = BiometricPrompt(this, executor, object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                        super.onAuthenticationError(errorCode, errString)
                        result.success(false) // Authentication failed
                    }

                    override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                        super.onAuthenticationSucceeded(authResult)
                        result.success(true) // Authentication succeeded
                    }

                    override fun onAuthenticationFailed() {
                        super.onAuthenticationFailed()
                        // This is called when a biometric is recognized but not accepted.
                        // The prompt remains open, so we don't send a result yet.
                    }
                })
                biometricPrompt.authenticate(promptInfo)
            }
            BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> {
                result.success(false) // No biometric features on this device
            }
            BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> {
                result.success(false) // Biometric features are currently unavailable
            }
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> {
                result.success(false) // No biometrics enrolled
            }
            else -> {
                result.success(false) // Other errors
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