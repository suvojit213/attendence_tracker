import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateService {
  static const platform = MethodChannel('com.suvojeet.attendance_tracker/updater');

  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      final response = await http.get(Uri.parse('https://api.github.com/repos/suvojit213/attendence_tracker/releases/latest'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> release = json.decode(response.body);
        String latestVersion = release['tag_name'].replaceFirst('v', ''); // Assuming tag names are like v1.0.0

        if (_isNewVersionAvailable(currentVersion, latestVersion)) {
          return {
            'newVersion': latestVersion,
            'downloadUrl': release['assets'][0]['browser_download_url'], // Assuming the first asset is the APK
          };
        }
      }
    } catch (e) {
      print('Error checking for update: $e');
    }
    return null;
  }

  static bool _isNewVersionAvailable(String currentVersion, String latestVersion) {
    List<int> currentParts = currentVersion.split('.').map(int.parse).toList();
    List<int> latestParts = latestVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) return true; // Latest version has more parts, so it's newer
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false; // Versions are the same or current is newer (if latest has fewer parts)
  }

  static Future<void> downloadAndInstallUpdate(String downloadUrl) async {
    if (Platform.isAndroid) {
      // Request storage permission for older Android versions
      if (await Permission.storage.request().isGranted) {
        try {
          await platform.invokeMethod('downloadAndInstall', {'url': downloadUrl});
        } on PlatformException catch (e) {
          print("Failed to invoke method: '${e.message}'.");
        }
      } else {
        // Handle permission denied
        print("Storage permission denied.");
      }
    }
  }
}