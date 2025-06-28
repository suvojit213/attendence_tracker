import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../models/attendance_status.dart';
import '../services/attendance_storage_service.dart';
import '../utils/app_colors.dart';
import '../widgets/attendance_day_details.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final AttendanceStorageService _storageService = AttendanceStorageService.instance;
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, AttendanceRecord> _attendanceRecords = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadAttendanceRecords();
  }

  Future<void> _loadAttendanceRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final records = await _storageService.getAttendanceRecordsForMonth(
        _focusedDay.year,
        _focusedDay.month,
      );
      
      final recordsMap = <String, AttendanceRecord>{};
      for (final record in records) {
        recordsMap[record.dateKey] = record;
      }
      
      setState(() {
        _attendanceRecords = recordsMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading attendance records: $e');
    }
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

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  AttendanceRecord? _getRecordForDay(DateTime day) {
    return _attendanceRecords[_getDateKey(day)];
  }

  Color _getDayColor(DateTime day) {
    final record = _getRecordForDay(day);
    
    if (record == null) {
      // No record - check if it's a future date
      if (day.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
        return AppColors.textLight; // Future dates
      }
      return AppColors.error; // Past dates without record (absent)
    }
    
    switch (record.status) {
      case AttendanceStatus.present:
        // Check if working hours are complete
        if (record.isPunchedOut && !record.isWorkingHoursComplete) {
          return AppColors.warning; // Present but incomplete hours
        }
        return AppColors.success; // Present with complete hours
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.leave:
        return AppColors.warning;
      case AttendanceStatus.weekOff:
        return AppColors.calendarWeekOff;
    }
  }

  Widget _buildCalendarDay(DateTime day, bool isSelected, bool isToday) {
    final record = _getRecordForDay(day);
    final dayColor = _getDayColor(day);
    final isCurrentMonth = day.month == _focusedDay.month;
    
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected 
            ? AppColors.primary 
            : (isToday ? AppColors.primaryLight.withOpacity(0.3) : null),
        borderRadius: BorderRadius.circular(8),
        border: isToday && !isSelected
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : (isCurrentMonth ? AppColors.textPrimary : AppColors.textLight),
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (record != null || (day.isBefore(DateTime.now()) && record == null))
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dayColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showDayDetailsDialog(DateTime selectedDay) async {
    final record = _getRecordForDay(selectedDay);
    
    await showDialog(
      context: context,
      builder: (context) => AttendanceDayDetails(
        date: selectedDay,
        record: record,
        onMarkLeave: () => _markLeaveOrWeekOff(selectedDay, AttendanceStatus.leave),
        onMarkWeekOff: () => _markLeaveOrWeekOff(selectedDay, AttendanceStatus.weekOff),
        onDelete: () => _deleteRecord(selectedDay),
      ),
    );
    
    // Refresh data after dialog closes
    await _loadAttendanceRecords();
  }

  Future<void> _markLeaveOrWeekOff(DateTime date, AttendanceStatus status) async {
    try {
      final success = await _storageService.markLeaveOrWeekOff(date, status);
      if (success) {
        Navigator.of(context).pop(); // Close dialog
        _showSuccessSnackBar('${status.displayName} marked successfully!');
        await _loadAttendanceRecords();
      } else {
        _showErrorSnackBar('Failed to mark ${status.displayName.toLowerCase()}');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  Future<void> _deleteRecord(DateTime date) async {
    try {
      final success = await _storageService.deleteAttendanceRecord(date);
      if (success) {
        Navigator.of(context).pop(); // Close dialog
        _showSuccessSnackBar('Record deleted successfully!');
        await _loadAttendanceRecords();
      } else {
        _showErrorSnackBar('Failed to delete record');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showLegendDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar
                Card(
                  margin: const EdgeInsets.all(16),
                  child: TableCalendar<AttendanceRecord>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: true,
                      weekendTextStyle: TextStyle(color: AppColors.calendarWeekend),
                      holidayTextStyle: TextStyle(color: AppColors.error),
                      selectedDecoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        return _buildCalendarDay(day, false, isSameDay(day, DateTime.now()));
                      },
                      selectedBuilder: (context, day, focusedDay) {
                        return _buildCalendarDay(day, true, isSameDay(day, DateTime.now()));
                      },
                      todayBuilder: (context, day, focusedDay) {
                        return _buildCalendarDay(day, false, true);
                      },
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      _showDayDetailsDialog(selectedDay);
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                      _loadAttendanceRecords();
                    },
                  ),
                ),
                
                // Legend
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Legend',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _buildLegendItem('Present', AppColors.success),
                              _buildLegendItem('Absent/Incomplete', AppColors.error),
                              _buildLegendItem('Leave', AppColors.warning),
                              _buildLegendItem('Week Off', AppColors.calendarWeekOff),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showLegendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calendar Legend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendDialogItem(
              'Green dot', 
              AppColors.success, 
              'Present with complete hours (9+ hours)'
            ),
            const SizedBox(height: 8),
            _buildLegendDialogItem(
              'Red dot', 
              AppColors.error, 
              'Absent or incomplete hours (less than 9 hours)'
            ),
            const SizedBox(height: 8),
            _buildLegendDialogItem(
              'Orange dot', 
              AppColors.warning, 
              'On leave'
            ),
            const SizedBox(height: 8),
            _buildLegendDialogItem(
              'Purple dot', 
              AppColors.calendarWeekOff, 
              'Week off'
            ),
            const SizedBox(height: 12),
            Text(
              'Tap on any date to view details or mark leave/week off.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDialogItem(String title, Color color, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

