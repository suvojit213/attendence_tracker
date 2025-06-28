import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../models/attendance_status.dart';
import '../services/attendance_storage_service.dart';
import '../utils/app_colors.dart';
import '../widgets/punch_button.dart';
import '../widgets/attendance_summary_card.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AttendanceStorageService _storageService = AttendanceStorageService.instance;
  AttendanceRecord? _todayRecord;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTodayRecord();
  }

  Future<void> _loadTodayRecord() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final today = DateTime.now();
      final record = await _storageService.getAttendanceRecord(today);
      setState(() {
        _todayRecord = record;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading today\'s record: $e');
    }
  }

  Future<void> _punchIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _storageService.punchIn(DateTime.now());
      if (success) {
        await _loadTodayRecord();
        _showSuccessSnackBar('Punched in successfully!');
      } else {
        _showErrorSnackBar('Failed to punch in. You may have already punched in today.');
      }
    } catch (e) {
      _showErrorSnackBar('Error punching in: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _punchOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _storageService.punchOut(DateTime.now());
      if (success) {
        await _loadTodayRecord();
        _showSuccessSnackBar('Punched out successfully!');
      } else {
        _showErrorSnackBar('Failed to punch out. Please punch in first.');
      }
    } catch (e) {
      _showErrorSnackBar('Error punching out: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              ).then((_) => _loadTodayRecord());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTodayRecord,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and Time Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateFormatter.format(now),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            timeFormatter.format(now),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Attendance Summary Card
                    AttendanceSummaryCard(
                      record: _todayRecord,
                      onRefresh: _loadTodayRecord,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Punch Buttons
                    Row(
                      children: [
                        Expanded(
                          child: PunchButton(
                            title: 'Punch In',
                            subtitle: _todayRecord?.punchInTime != null
                                ? DateFormat('h:mm a').format(_todayRecord!.punchInTime!)
                                : 'Not punched in',
                            icon: Icons.login,
                            gradient: AppColors.successGradient,
                            onPressed: _todayRecord?.isPunchedIn == true ? null : _punchIn,
                            isCompleted: _todayRecord?.isPunchedIn == true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: PunchButton(
                            title: 'Punch Out',
                            subtitle: _todayRecord?.punchOutTime != null
                                ? DateFormat('h:mm a').format(_todayRecord!.punchOutTime!)
                                : 'Not punched out',
                            icon: Icons.logout,
                            gradient: AppColors.errorGradient,
                            onPressed: (_todayRecord?.isPunchedIn != true || _todayRecord?.isPunchedOut == true) 
                                ? null 
                                : _punchOut,
                            isCompleted: _todayRecord?.isPunchedOut == true,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Stats
                    if (_todayRecord != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today\'s Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildStatRow(
                                'Status',
                                _todayRecord!.status.displayName,
                                _getStatusColor(_todayRecord!.status),
                              ),
                              const SizedBox(height: 8),
                              if (_todayRecord!.workingHours > 0) ...[
                                _buildStatRow(
                                  'Working Hours',
                                  _todayRecord!.formattedWorkingHours,
                                  _todayRecord!.isWorkingHoursComplete 
                                      ? AppColors.success 
                                      : AppColors.warning,
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (!_todayRecord!.isWorkingHoursComplete && 
                                  _todayRecord!.workingHours > 0) ...[
                                _buildStatRow(
                                  'Hours Remaining',
                                  '${(9 - _todayRecord!.workingHours).toStringAsFixed(1)}h',
                                  AppColors.warning,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.leave:
        return AppColors.warning;
      case AttendanceStatus.weekOff:
        return AppColors.calendarWeekOff;
    }
  }
}

