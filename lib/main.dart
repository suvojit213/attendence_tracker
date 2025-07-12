import 'package:attendance_tracker/screens/about_screen.dart';
import 'package:attendance_tracker/services/theme_service.dart';
import 'package:attendance_tracker/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/setup_screen.dart'; // Import the new setup screen

final themeService = ThemeService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isSetupComplete = prefs.getBool('isSetupComplete') ?? false;

  runApp(AttendanceTrackerApp(isSetupComplete: isSetupComplete));
}

class AttendanceTrackerApp extends StatelessWidget {
  final bool isSetupComplete;
  const AttendanceTrackerApp({super.key, required this.isSetupComplete});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeService,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'Attendance Tracker Pro',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeMode,
          initialRoute: isSetupComplete ? '/home' : '/setup',
          routes: {
            '/setup': (context) => const SetupScreen(),
            '/home': (context) => const HomeScreen(),
            '/about': (context) => const AboutScreen(),
          },
        );
      },
    );
  }
}