package com.suvojeet.attendance_tracker

import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.widget.Toast
import androidx.core.content.FileProvider
import java.io.File

class AppUpdater(private val context: Context) {

    private var downloadId: Long = -1L

    fun downloadAndInstall(url: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (!context.packageManager.canRequestPackageInstalls()) {
                Toast.makeText(context, "Please enable installation from unknown sources", Toast.LENGTH_LONG).show()
                val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
                intent.data = Uri.parse("package:" + context.packageName)
                context.startActivity(intent)
                return
            }
        }

        val request = DownloadManager.Request(Uri.parse(url))
            .setTitle("App Update")
            .setDescription("Downloading new version")
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, "attendance_tracker_update.apk")

        val downloadManager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        downloadId = downloadManager.enqueue(request)

        val onComplete = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val id = intent?.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1)
                if (id == downloadId) {
                    installApk(downloadManager.getUriForDownloadedFile(downloadId))
                    context?.unregisterReceiver(this)
                }
            }
        }
        context.registerReceiver(onComplete, IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE))
    }

    private fun installApk(uri: Uri?) {
        if (uri == null) {
            Toast.makeText(context, "Download failed, URI is null", Toast.LENGTH_LONG).show()
            return
        }

        val file = File(context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS), "attendance_tracker_update.apk")
        val apkUri = FileProvider.getUriForFile(context, context.packageName + ".fileprovider", file)

        val installIntent = Intent(Intent.ACTION_VIEW)
        installIntent.setDataAndType(apkUri, "application/vnd.android.package-archive")
        installIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        installIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(installIntent)
    }
}