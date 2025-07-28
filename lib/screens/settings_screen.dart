import 'package:attendance_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:attendance_tracker/services/attendance_storage_service.dart';
import 'package:attendance_tracker/utils/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AttendanceStorageService _storageService = AttendanceStorageService.instance;
  double _standardWorkingHours = 9.0;

  @override
  void initState() {
    super.initState();
    _loadStandardWorkingHours();
  }

  Future<void> _loadStandardWorkingHours() async {
    final hours = await _storageService.getStandardWorkingHours();
    setState(() {
      _standardWorkingHours = hours;
    });
  }

  Future<void> _saveStandardWorkingHours(double hours) async {
    await _storageService.saveStandardWorkingHours(hours);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Standard working hours saved: ${hours.toStringAsFixed(1)} hours'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 10),
                        const Text(
                          'Standard Workday Duration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Set the number of hours considered a full workday:',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _standardWorkingHours,
                            min: 1.0,
                            max: 12.0,
                            divisions: 22, // 1.0 to 12.0 with 0.5 increments
                            label: _standardWorkingHours.toStringAsFixed(1),
                            onChanged: (newValue) {
                              setState(() {
                                _standardWorkingHours = newValue;
                              });
                            },
                            onChangeEnd: (newValue) {
                              _saveStandardWorkingHours(newValue);
                            },
                          ),
                        ),
                        Text(
                          '${_standardWorkingHours.toStringAsFixed(1)} hours',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Attendance will be marked as present if working hours meet or exceed this value.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.brightness_6_rounded, color: Theme.of(context).primaryColor),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: themeService.value == ThemeMode.dark,
                  onChanged: (value) {
                    themeService.toggleTheme(value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.info_rounded, color: Theme.of(context).primaryColor),
                title: const Text('About This App'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded),
                onTap: () {
                  Navigator.of(context).pushNamed('/about');
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.volunteer_activism_rounded, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 10),
                        const Text(
                          'Support Development',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Developing an application of this quality typically costs around ₹10,000-₹15,000 INR. However, I am providing this app to you completely free of charge.',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'If you find it useful and wish to support its continuous improvement, you can donate:',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      'UPI ID: suvojeetsengupta2.wallet@phonepe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Your support motivates monthly updates and new features!',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}