import 'package:attendance_tracker/screens/about_screen.dart';
import 'package:attendance_tracker/services/theme_service.dart';
import 'package:attendance_tracker/utils/theme.dart';
import 'package:attendance_tracker/screens/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'package:attendance_tracker/services/auth_service.dart'; // Import your AuthService

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
  final AuthService _authService = AuthService();
  bool _isAuthenticated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    bool canAuthenticate = await _authService.canAuthenticate();
    if (canAuthenticate) {
      bool authenticated = await _authService.authenticate();
      setState(() {
        _isAuthenticated = authenticated;
        _isLoading = false;
      });
    } else {
      // If biometrics are not available or not set up, allow access
      setState(() {
        _isAuthenticated = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (!_isAuthenticated) {
      // You might want to show an error screen or a fallback login here
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Authentication Required to use the app.'),
          ),
        ),
      );
    }

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