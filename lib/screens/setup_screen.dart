import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart'; // Assuming AppColors is defined here

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
        _errorMessage = 'Invalid access code. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/attendance_tracker_icon.png', // Ensure this path is correct
                height: 120,
              ),
              const SizedBox(height: 32.0),
              Text(
                'Welcome to Attendance Tracker',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              Text(
                'Please enter the access code to continue.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textColor,
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
                  labelStyle: TextStyle(color: AppColors.accentColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: AppColors.accentColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: AppColors.accentColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: AppColors.primaryColor, width: 2.0),
                  ),
                  errorText: _errorMessage,
                  prefixIcon: Icon(Icons.lock, color: AppColors.accentColor),
                ),
                style: TextStyle(color: AppColors.textColor),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _verifyAccessCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  'Unlock App',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.backgroundColor, // Text color for button
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
