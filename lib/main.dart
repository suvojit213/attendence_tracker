import 'package:attendance_tracker/screens/about_screen.dart';
import 'package:attendance_tracker/services/theme_service.dart';
import 'package:attendance_tracker/utils/theme.dart';
import 'package:attendance_tracker/screens/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'package:attendance_tracker/services/donation_service.dart';

final themeService = ThemeService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AttendanceTrackerApp());
}

class AttendanceTrackerApp extends StatefulWidget {
  const AttendanceTrackerApp({super.key});

  @override
  State<AttendanceTrackerApp> createState() => _AttendanceTrackerAppState();
}

class _AttendanceTrackerAppState extends State<AttendanceTrackerApp> {
  @override
  void initState() {
    super.initState();
    _checkDonationPopup();
  }

  void _checkDonationPopup() async {
    await DonationService().showDonationPopupIfNeeded(context);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeService,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'Attendance Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeMode,
          home: const HomeScreen(),
          routes: {
            '/home': (context) => const HomeScreen(),
            '/about': (context) => const AboutScreen(),
            '/reports': (context) => const ReportsScreen(),
          },
        );
      },
    );
  }
}