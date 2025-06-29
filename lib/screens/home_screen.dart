import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../models/attendance_status.dart';
import '../services/attendance_storage_service.dart';
import '../utils/app_colors.dart';
import '../widgets/punch_button.dart';
import '../widgets/attendance_summary_card.dart';
import 'calendar_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AttendanceStorageService _storageService = AttendanceStorageService.instance;
  AttendanceRecord? _todayRecord;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTodayRecord();
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
    super.dispose();
  }

  Future<void> _loadTodayRecord() async {
    if (mounted) setState(() => _isLoading = true);

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
        _showErrorSnackBar('Error loading today\'s record: $e');
      }
    } finally {
        if(mounted) setState(() => _isLoading = false);
    }
  }

  // Generic punch-in logic (automatic or manual)
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

    if (mounted) setState(() => _isLoading = true);

    try {
      final success = await _storageService.punchIn(now, punchTime: manualTime);
      if (success && mounted) {
        await _loadTodayRecord();
        _showSuccessSnackBar('Punched in successfully! 🎉');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Generic punch-out logic (automatic or manual)
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
    
    if (mounted) setState(() => _isLoading = true);

    try {
      final success = await _storageService.punchOut(now, punchTime: manualTime);
      if (success && mounted) {
        await _loadTodayRecord();
        _showSuccessSnackBar('Punched out successfully! 👋');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Show time picker for manual punch-in
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

  // Show time picker for manual punch-out
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
           _showErrorSnackBar("Punch-out time cannot be before punch-in time.");
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
                  color: AppColors.primary,
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
                'Complete 9 hours of work to mark attendance as present.',
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
                foregroundColor: AppColors.primary,
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
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
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
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: AppColors.textSecondary,
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
    final dateFormatter = DateFormat('EEEE, MMMM d, הערב');
    final timeFormatter = DateFormat('h:mm a');

    // Button states
    final bool canPunchIn = _todayRecord?.isPunchedIn != true;
    final bool canPunchOut = _todayRecord?.isPunchedIn == true && _todayRecord?.isPunchedOut != true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance Tracker Pro'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
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
            icon: const Icon(Icons.person_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
            tooltip: 'About',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadTodayRecord,
              color: AppColors.primary,
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
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.today_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  dateFormatter.format(now),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            StreamBuilder(
                              stream: Stream.periodic(const Duration(seconds: 1)),
                              builder: (context, snapshot) {
                                return Text(
                                  timeFormatter.format(DateTime.now()),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
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
                      
                      AttendanceSummaryCard(
                        record: _todayRecord,
                        onRefresh: _loadTodayRecord,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: PunchButton(
                              title: 'Punch In',
                              subtitle: _todayRecord?.punchInTime != null
                                  ? DateFormat('h:mm a').format(_todayRecord!.punchInTime!)
                                  : 'Tap to Punch In',
                              icon: Icons.login_rounded,
                              gradient: AppColors.successGradient,
                              onPressed: canPunchIn ? () => _performPunchIn() : null,
                              isCompleted: !canPunchIn,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: PunchButton(
                              title: 'Punch Out',
                              subtitle: _todayRecord?.punchOutTime != null
                                  ? DateFormat('h:mm a').format(_todayRecord!.punchOutTime!)
                                  : 'Tap to Punch Out',
                              icon: Icons.logout_rounded,
                              gradient: AppColors.errorGradient,
                              onPressed: canPunchOut ? () => _performPunchOut() : null,
                              isCompleted: _todayRecord?.isPunchedOut == true,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),

                      // Manual Punch Buttons
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16)
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: canPunchIn ? _manualPunchIn : null, 
                              icon: Icon(
                                Icons.edit_calendar_outlined, 
                                color: canPunchIn ? AppColors.primary : Colors.grey,
                              ), 
                              label: Text(
                                'Manual Punch In',
                                style: TextStyle(
                                  color: canPunchIn ? AppColors.primary : Colors.grey,
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
                            color: Colors.white,
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
                                        color: AppColors.secondary,
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
                                      'Today\'s Summary',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
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
            ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
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
              color: AppColors.textSecondary,
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
        return AppColors.calendarWeekOff;
    }
  }
}

