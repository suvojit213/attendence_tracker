import 'package:flutter/services.dart';

class AuthService {
  static const MethodChannel _channel = MethodChannel('com.example.attendance_tracker/biometric');

  Future<bool> authenticate() async {
    try {
      final bool result = await _channel.invokeMethod('authenticate');
      return result;
    } on PlatformException catch (e) {
      print("Failed to authenticate: '${e.message}');
      return false;
    }
  }
}