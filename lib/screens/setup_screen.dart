import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _accessCodeController = TextEditingController();
  final String _correctAccessCode = '123456';
  String? _errorMessage;

  Future<void> _verifyAccessCode() async {
    if (_accessCodeController.text == _correctAccessCode) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isSetupComplete', true);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      setState(() {
        _errorMessage = null; // Clear previous error message
      });
      _showUnauthorizedDialog();
    }
  }

  void _showUnauthorizedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Unauthorized Access',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You are not authorized to use this application. Access is restricted.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'To gain access, please contact the app developer. This is a one-time setup requirement.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                import 'package:flutter/services.dart';

// ... (rest of the imports)

class _SetupScreenState extends State<SetupScreen> {
  static const platform = MethodChannel('com.example.attendance_tracker/email');

  // ... (rest of the class)

  Future<void> _sendEmail() async {
    try {
      await platform.invokeMethod('sendEmail', {
        'to': 'suvojitsengupta21@gmail.com',
        'subject': 'Attendance Tracker App Access Request',
        'body': 'Hello, I would like to request the access code for the Attendance Tracker app.'
      });
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch email client. Please contact suvojitsengupta21@gmail.com manually.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ... (in the build method, replace the onPressed of the email button)
  onPressed: _sendEmail,
                icon: const Icon(Icons.email_rounded, color: Colors.white),
                label: const Text('Contact Developer', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss dialog
                  _accessCodeController.clear(); // Clear the input field
                },
                child: Text(
                  'Try Again',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/attendance_tracker_icon.png',
                height: 120,
              ),
              const SizedBox(height: 32.0),
              Text(
                'Welcome to Attendance Tracker',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              Text(
                'Please enter the access code to continue.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32.0),
              TextField(
                controller: _accessCodeController,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Access Code',
                  labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  errorText: _errorMessage,
                  prefixIcon: Icon(Icons.lock, color: Theme.of(context).primaryColor),
                ),
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _verifyAccessCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text(
                  'Unlock App',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _accessCodeController.dispose();
    super.dispose();
  }
}