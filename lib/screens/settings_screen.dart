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
              child: ListTile(
                leading: Icon(Icons.info_rounded, color: Theme.of(context).primaryColor),
                title: const Text('About This App'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded),
                onTap: () {
                  Navigator.of(context).pushNamed('/about');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}