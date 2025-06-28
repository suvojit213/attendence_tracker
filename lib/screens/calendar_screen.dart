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

  int _presentCount = 0;
  int _absentCount = 0;
  int _leaveCount = 0;
  int _weekOffCount = 0;

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
      _presentCount = 0;
      _absentCount = 0;
      _leaveCount = 0;
      _weekOffCount = 0;

      for (final record in records) {
        recordsMap[record.dateKey] = record;
        if (record.status == AttendanceStatus.present) {
          _presentCount++;
        } else if (record.status == AttendanceStatus.absent) {
          _absentCount++;
        } else if (record.status == AttendanceStatus.leave) {
          _leaveCount++;
        } else if (record.status == AttendanceStatus.weekOff) {
          _weekOffCount++;
        }
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
        if (record.isPunchedIn && record.isPunchedOut) {
          // If working hours are less than 1 minute or less than 9 hours, mark as absent
          if (record.workingHours * 60 < 1 || record.workingHours < 9.0) {
            return AppColors.error;
          }
          return AppColors.success;
        }
        return AppColors.warning; // Punched in but not out
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.leave:
        return AppColors.leave;
      case AttendanceStatus.weekOff:
        return AppColors.weekOff;
      default:
        return AppColors.textLight;
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _showAttendanceDetails(selectedDay);
  }

  void _showAttendanceDetails(DateTime date) {
    final record = _getRecordForDay(date);
    // isFutureDate should only check if the date is strictly in the future, not including today
    final isFutureDate = date.isAfter(DateTime.now().endOfDay());

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return AttendanceDayDetails(
          date: date,
          record: record,
          isFutureDate: isFutureDate,
          onPunchIn: (selectedDate) async {
            final success = await _storageService.punchIn(selectedDate);
            if (success) {
              _showSuccessSnackBar('Punch-in successful!');
              _loadAttendanceRecords();
            } else {
              _showErrorSnackBar('Failed to punch-in.');
            }
            Navigator.pop(context);
          },
          onPunchOut: (selectedDate) async {
            final success = await _storageService.punchOut(selectedDate);
            if (success) {
              _showSuccessSnackBar('Punch-out successful!');
              _loadAttendanceRecords();
            } else {
              _showErrorSnackBar('Failed to punch-out.');
            }
            Navigator.pop(context);
          },
          onMarkLeaveOrWeekOff: (selectedDate, status) async {
            final success = await _storageService.markLeaveOrWeekOff(selectedDate, status);
            if (success) {
              _showSuccessSnackBar('${status.value} marked for ${DateFormat('MMM dd, yyyy').format(selectedDate)}');
              _loadAttendanceRecords();
            } else {
              _showErrorSnackBar('Failed to mark ${status.value}.');
            }
            Navigator.pop(context);
          },
          onDeleteRecord: (selectedDate) async {
            final success = await _storageService.deleteAttendanceRecord(selectedDate);
            if (success) {
              _showSuccessSnackBar('Record deleted for ${DateFormat('MMM dd, yyyy').format(selectedDate)}');
              _loadAttendanceRecords();
            } else {
              _showErrorSnackBar('Failed to delete record.');
            }
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Calendar'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      color: AppColors.primary,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                    leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.primary),
                    rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.primary),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: TextStyle(color: AppColors.textDark),
                    weekendTextStyle: TextStyle(color: AppColors.textDark),
                    holidayTextStyle: TextStyle(color: AppColors.textDark),
                  ),
                  onDaySelected: _onDaySelected,
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                    _loadAttendanceRecords();
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      return Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(color: _getDayColor(day)),
                        ),
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '${day.day}',
                            style: TextStyle(color: AppColors.white),
                          ),
                        ),
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      return Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '${day.day}',
                            style: TextStyle(color: AppColors.white),
                          ),
                        ),
                      );
                    },
                    markerBuilder: (context, day, events) {
                      final record = _getRecordForDay(day);
                      if (record != null) {
                        return Positioned(
                          bottom: 1,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getDayColor(day), // Use the same color logic as the day text
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildStatRow('Present', _presentCount, AppColors.success),
                      _buildStatRow('Absent', _absentCount, AppColors.error),
                      _buildStatRow('Leave', _leaveCount, AppColors.leave),
                      _buildStatRow('Week Off', _weekOffCount, AppColors.weekOff),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

extension DateTimeExtension on DateTime {
  DateTime endOfDay() {
    return DateTime(year, month, day, 23, 59, 59, 999, 999);
  }
}


