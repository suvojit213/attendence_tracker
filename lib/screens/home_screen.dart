import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../models/attendance_status.dart';
import '../services/attendance_storage_service.dart';
import '../utils/app_colors.dart';
import '../widgets/punch_button.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AttendanceStorageService _storageService = AttendanceStorageService.instance;
  AttendanceRecord? _todayRecord;
  bool _isLoading = false;
  DateTime? _punchInTime;
  Timer? _timer;
  String _elapsedTime = '00:00:00';
  double _standardWorkingHours = 9.0; // Default value

  int _weeklyPresentCount = 0;
  int _weeklyAbsentCount = 0;
  int _weeklyLeaveCount = 0;
  int _weeklyWeekOffCount = 0;
  double _weeklyTotalWorkingHours = 0.0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTodayRecord();
    _loadActivePunchInTime();
    _loadStandardWorkingHours();
    _loadWeeklySummary();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadActivePunchInTime() async {
    final activePunchIn = await _storageService.getActivePunchInTime();
    if (mounted) {
      setState(() {
        _punchInTime = activePunchIn;
        if (_punchInTime != null) {
          _startTimer();
        } else {
          _elapsedTime = '00:00:00';
        }
      });
    }
  }

  void _startTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_punchInTime != null) {
        final duration = DateTime.now().difference(_punchInTime!);
        if (mounted) {
          setState(() {
            _elapsedTime = _formatDuration(duration);
          });
        }
      } else {
        _timer?.cancel();
        if (mounted) {
          setState(() {
            _elapsedTime = '00:00:00';
          });
        }
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '${hours}:${minutes}:${seconds}';
  }

  Future<void> _loadTodayRecord() async {
    if (mounted) setState(() {
      _isLoading = true;
    });

    try {
      await _storageService.init(); // Ensure service is initialized
      final today = DateTime.now();
      final record = await _storageService.getAttendanceRecord(today);
      if (mounted) {
        setState(() {
          _todayRecord = record;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("Error loading today's record: $e");
      }
    } finally {
        if(mounted) setState(() {
          _isLoading = false;
        });
    }
  }

  Future<void> _loadStandardWorkingHours() async {
    final hours = await _storageService.getStandardWorkingHours();
    if (mounted) {
      setState(() {
        _standardWorkingHours = hours;
      });
    }
  }

  Future<void> _loadWeeklySummary() async {
    if (mounted) setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
      final endOfWeek = startOfWeek.add(const Duration(days: 6)); // Sunday

      final records = await _storageService.getAttendanceRecordsForDateRange(startOfWeek, endOfWeek);

      int present = 0;
      int absent = 0;
      int leave = 0;
      int weekOff = 0;
      double totalWorkingHours = 0.0;

      for (final record in records) {
        switch (record.status) {
          case AttendanceStatus.present:
            present++;
            totalWorkingHours += record.workingHours;
            break;
          case AttendanceStatus.absent:
            absent++;
            break;
          case AttendanceStatus.leave:
            leave++;
            break;
          case AttendanceStatus.weekOff:
            weekOff++;
            break;
        }
      }

      if (mounted) {
        setState(() {
          _weeklyPresentCount = present;
          _weeklyAbsentCount = absent;
          _weeklyLeaveCount = leave;
          _weeklyWeekOffCount = weekOff;
          _weeklyTotalWorkingHours = totalWorkingHours;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error loading weekly summary: $e');
      }
    } finally {
      if (mounted) setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performPunchIn({DateTime? manualTime}) async {
    final now = DateTime.now();
    
    if (!_storageService.isPunchingAllowed(now)) {
      _showErrorSnackBar(_storageService.getPastDateErrorMessage());
      return;
    }

    if (manualTime != null && manualTime.isAfter(DateTime.now())) {
      _showErrorSnackBar("Manual punch-in time cannot be in the future.");
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final success = await _storageService.punchIn(now, punchTime: manualTime);
      if (success && mounted) {
        await _loadTodayRecord();
        await _loadActivePunchInTime();
        await _loadWeeklySummary();
        _showSuccessSnackBar('Punched in successfully! 🎉');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _performPunchOut({DateTime? manualTime}) async {
    final now = DateTime.now();
    
    if (!_storageService.isPunchingAllowed(now)) {
      _showErrorSnackBar(_storageService.getPastDateErrorMessage());
      return;
    }

     if (manualTime != null && manualTime.isAfter(DateTime.now())) {
      _showErrorSnackBar("Manual punch-out time cannot be in the future.");
      return;
    }
    
    setState(() { _isLoading = true; });

    try {
      final success = await _storageService.punchOut(now, punchTime: manualTime);
      if (success && mounted) {
        await _loadTodayRecord();
        await _loadActivePunchInTime();
        await _loadWeeklySummary();
        _showSuccessSnackBar('Punched out successfully! 👋');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _manualPunchIn() async {
    final now = DateTime.now();
    final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
        helpText: 'Select Punch-In Time',
    );

    if (selectedTime != null) {
        final selectedDateTime = DateTime(
            now.year, now.month, now.day,
            selectedTime.hour, selectedTime.minute
        );
        await _performPunchIn(manualTime: selectedDateTime);
    }
  }

  Future<void> _manualPunchOut() async {
    final now = DateTime.now();
    final record = await _storageService.getAttendanceRecord(now);

    if (record?.punchInTime == null) {
      _showErrorSnackBar("You must punch in first.");
      return;
    }

    final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
        helpText: 'Select Punch-Out Time',
    );

    if (selectedTime != null) {
        final selectedDateTime = DateTime(
            now.year, now.month, now.day,
            selectedTime.hour, selectedTime.minute
        );

        if(selectedDateTime.isBefore(record!.punchInTime!)) {
           _showErrorSnackBar("Punch-out time cannot be earlier than punch-in time.");
           return;
        }

        await _performPunchOut(manualTime: selectedDateTime);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Attendance Policy'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPolicyItem(
                Icons.today_rounded,
                'Current Date Only',
                'You can only punch in/out for today. Past date punching is not allowed.',
              ),
              const SizedBox(height: 16),
              _buildPolicyItem(
                Icons.access_time_rounded,
                'Working Hours',
                'Complete ${_standardWorkingHours.toInt()} hours of work to mark attendance as present.',
              ),
              const SizedBox(height: 16),
              _buildPolicyItem(
                Icons.security_rounded,
                'Data Security',
                'All attendance data is stored securely on your device.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPolicyItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormatter = DateFormat('EEEE, MMMM d');
    final timeFormatter = DateFormat('h:mm a');

    final bool canPunchIn = _todayRecord?.isPunchedIn != true;
    final bool canPunchOut = _todayRecord?.isPunchedIn == true && _todayRecord?.isPunchedOut != true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Tracker Pro'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: _showInfoDialog,
            tooltip: 'Attendance Policy',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              ).then((_) => _loadTodayRecord());
            },
            tooltip: 'View Calendar',
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => _loadStandardWorkingHours());
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadTodayRecord,
              color: Theme.of(context).primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: Theme.of(context).brightness == Brightness.light
                              ? AppColors.primaryGradient
                              : AppColors.primaryGradientDark,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Indicator
                            Row(
                              children: [
                                Icon(
                                  _todayRecord?.isPunchedIn == true && _todayRecord?.isPunchedOut != true
                                      ? Icons.timer_rounded // Punched In
                                      : _todayRecord?.isPunchedOut == true
                                          ? Icons.check_circle_rounded // Punched Out
                                          : Icons.circle_outlined, // Not Punched In
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _todayRecord?.isPunchedIn == true && _todayRecord?.isPunchedOut != true
                                      ? 'Punched In'
                                      : _todayRecord?.isPunchedOut == true
                                          ? 'Punched Out'
                                          : 'Not Punched In',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Current Time
                            StreamBuilder(
                              stream: Stream.periodic(const Duration(seconds: 1)),
                              builder: (context, snapshot) {
                                return Text(
                                  timeFormatter.format(DateTime.now()),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            // Current Date
                            Text(
                              dateFormatter.format(now),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Elapsed Time (if punched in)
                            if (_punchInTime != null && _todayRecord?.punchOutTime == null) ...[
                              Text(
                                'Elapsed: $_elapsedTime',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Working Hours Progress Bar
                            Text(
                              'Working Hours: ${_todayRecord?.formattedWorkingHours ?? '0h 0m'} / ${_standardWorkingHours.toStringAsFixed(1)}h',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: (_todayRecord?.workingHours ?? 0.0) / _standardWorkingHours,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Text(
                                'Today Only - Past Date Punching Disabled',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: canPunchIn ? () => _performPunchIn() : null,
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('Punch In'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: canPunchOut ? () => _performPunchOut() : null,
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Punch Out'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16)
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: canPunchIn ? _manualPunchIn : null, 
                              icon: Icon(
                                Icons.edit_calendar_outlined, 
                                color: canPunchIn ? Theme.of(context).primaryColor : Colors.grey,
                              ), 
                              label: Text(
                                'Manual Punch In',
                                style: TextStyle(
                                  color: canPunchIn ? Theme.of(context).primaryColor : Colors.grey,
                                  fontWeight: FontWeight.w600
                                ),
                              )
                            ),
                             TextButton.icon(
                              onPressed: canPunchOut ? _manualPunchOut : null, 
                              icon: Icon(
                                Icons.edit_calendar_outlined,
                                color: canPunchOut ? AppColors.error : Colors.grey,
                                ), 
                              label: Text(
                                'Manual Punch Out',
                                style: TextStyle(
                                  color: canPunchOut ? AppColors.error : Colors.grey,
                                   fontWeight: FontWeight.w600
                                ),
                              )
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      if (_todayRecord != null) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.secondary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.analytics_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Today's Summary",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildStatRow(
                                  'Status',
                                  _todayRecord!.status.displayName,
                                  _getStatusColor(_todayRecord!.status),
                                ),
                                const SizedBox(height: 12),
                                if (_todayRecord!.punchInTime != null) ...[
                                  _buildStatRow(
                                    'Punch In Time',
                                    DateFormat('h:mm a').format(_todayRecord!.punchInTime!),
                                    AppColors.success,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (_todayRecord!.punchOutTime != null) ...[
                                  _buildStatRow(
                                    'Punch Out Time',
                                    DateFormat('h:mm a').format(_todayRecord!.punchOutTime!),
                                    AppColors.error,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (_todayRecord!.workingHours > 0) ...[
                                  _buildStatRow(
                                    'Working Hours',
                                    _todayRecord!.formattedWorkingHours,
                                    _todayRecord!.isWorkingHoursComplete 
                                        ? AppColors.success 
                                        : AppColors.warning,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (!_todayRecord!.isWorkingHoursComplete && 
                                    _todayRecord!.isPunchedIn &&
                                    !_todayRecord!.isPunchedOut) ...[
                                  _buildStatRow(
                                    'Hours Remaining',
                                    '${(_standardWorkingHours - _todayRecord!.workingHours).toStringAsFixed(1)}h',
                                    AppColors.warning,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildWeeklySummary(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWeeklySummary() {
    final totalDays = _weeklyPresentCount + _weeklyAbsentCount + _weeklyLeaveCount + _weeklyWeekOffCount;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Weekly Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressStatRow('Present', _weeklyPresentCount, totalDays, AppColors.success),
            const SizedBox(height: 12),
            _buildProgressStatRow('Absent', _weeklyAbsentCount, totalDays, AppColors.error),
            const SizedBox(height: 12),
            _buildProgressStatRow('Leave', _weeklyLeaveCount, totalDays, AppColors.warning),
            const SizedBox(height: 12),
            _buildProgressStatRow('Week Off', _weeklyWeekOffCount, totalDays, AppColors.weekOff),
            const SizedBox(height: 12),
            _buildStatRow('Total Working Hours', '${_weeklyTotalWorkingHours.toStringAsFixed(1)}h', Theme.of(context).primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStatRow(String label, int count, int total, Color color) {
    final percentage = total > 0 ? count / total : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            Text(
              '${count} (${(percentage * 100).toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
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
        return AppColors.weekOff;
    }
  }
}
