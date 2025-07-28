import 'package:attendance_tracker/screens/about_screen.dart';
import 'package:attendance_tracker/services/theme_service.dart';
import 'package:attendance_tracker/utils/theme.dart';
import 'package:attendance_tracker/screens/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'package:attendance_tracker/services/auth_service.dart'; // Import your new AuthService

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
  bool _isFirstLaunch = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = prefs.getBool('first_launch') ?? true;

    if (_isFirstLaunch) {
      // Attempt to authenticate for the first time setup
      bool authenticated = await _authService.authenticate();
      if (authenticated) {
        await prefs.setBool('first_launch', false);
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
          _isFirstLaunch = false;
        });
      } else {
        // If first-time authentication fails, keep _isFirstLaunch true
        // and show the authentication required message.
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    } else {
      // Regular authentication for subsequent launches
      bool authenticated = await _authService.authenticate();
      setState(() {
        _isAuthenticated = authenticated;
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
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Authentication Required to use the app.'),
                if (_isFirstLaunch)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        // Retry authentication for first-time setup
                        bool authenticated = await _authService.authenticate();
                        if (authenticated) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('first_launch', false);
                          setState(() {
                            _isAuthenticated = true;
                            _isFirstLaunch = false;
                          });
                        }
                      },
                      child: const Text('Set up Biometrics/Password'),
                    ),
                  ),
              ],
            ),
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