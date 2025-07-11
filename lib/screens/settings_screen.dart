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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
                        Icon(Icons.access_time_rounded, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          'Standard Workday Duration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Set the number of hours considered a full workday:',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
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
                            activeColor: AppColors.primary,
                            inactiveColor: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        Text(
                          '${_standardWorkingHours.toStringAsFixed(1)} hours',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Attendance will be marked as present if working hours meet or exceed this value.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
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
