import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../models/attendance_status.dart';
import '../services/attendance_storage_service.dart';
import '../utils/app_colors.dart';

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
      for (final record in records) {
        recordsMap[record.dateKey] = record;
      }
      
      _presentCount = 0;
      _absentCount = 0;
      _leaveCount = 0;
      _weekOffCount = 0;

      final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        final day = DateTime(_focusedDay.year, _focusedDay.month, i);
        final record = recordsMap[_getDateKey(day)];

        if (day.isAfter(DateTime.now())) {
          continue;
        }

        if (record == null) {
          if (day.weekday != DateTime.saturday && day.weekday != DateTime.sunday) {
            _absentCount++;
          }
        } else {
          switch (record.status) {
            case AttendanceStatus.present:
              if (record.isPunchedIn && record.isPunchedOut && record.workingHours >= 9.0) {
                _presentCount++;
              } else {
                _absentCount++; 
              }
              break;
            case AttendanceStatus.absent:
              _absentCount++;
              break;
            case AttendanceStatus.leave:
              _leaveCount++;
              break;
            case AttendanceStatus.weekOff:
              _weekOffCount++;
              break;
          }
        }
      }
      
      if(mounted) {
        setState(() {
          _attendanceRecords = recordsMap;
          _isLoading = false;
        });
      }
    } catch (e) {
       if(mounted) {
        setState(() {
          _isLoading = false;
        });
       }
      _showErrorSnackBar('Error loading attendance records: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
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
    if (!mounted) return;
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
      if (day.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
        return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
      }
      return AppColors.error;
    }

    switch (record.status) {
      case AttendanceStatus.present:
        if (record.isPunchedIn && record.isPunchedOut) {
          if (record.workingHours * 60 < 1 || record.workingHours < 9.0) {
            return AppColors.error;
          }
          return AppColors.success;
        }
        return AppColors.warning;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.leave:
        return AppColors.warning;
      case AttendanceStatus.weekOff:
        return AppColors.weekOff;
      default:
        return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Calendar'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TableCalendar(
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
                            color: Theme.of(context).primaryColor,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                          leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).primaryColor),
                          rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).primaryColor),
                        ),
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          todayDecoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          defaultTextStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                          weekendTextStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                          holidayTextStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        onDaySelected: _onDaySelected,
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                          _loadAttendanceRecords();
                        },
                        calendarBuilders: CalendarBuilders(
                           markerBuilder: (context, day, events) {
                            final record = _getRecordForDay(day);
                            if (record != null) {
                              return Positioned(
                                bottom: 1,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _getDayColor(day),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSelectedDayDetails(),
                  const SizedBox(height: 20),
                  _buildMonthlySummary(),
                ],
              ),
            ),
    );
  }

  Widget _buildSelectedDayDetails() {
    if (_selectedDay == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Please select a day to see details.", textAlign: TextAlign.center,),
        ),
      );
    }
    
    final record = _getRecordForDay(_selectedDay!);
    final isFutureDate = _selectedDay!.isAfter(DateTime.now().endOfDay());
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateFormatter.format(_selectedDay!),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
            const Divider(height: 20),
            if (record != null)
              _buildAttendanceInfo(record, timeFormatter)
            else
              _buildNoRecordInfo(isFutureDate),
            const SizedBox(height: 20),
            _buildActionButtons(record, isFutureDate),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceInfo(AttendanceRecord record, DateFormat timeFormatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Status', record.status.displayName, _getStatusIcon(record.status), _getStatusColor(record.status)),
        if (record.punchInTime != null)
          _buildInfoRow('Punch In', timeFormatter.format(record.punchInTime!), Icons.login, AppColors.success),
        if (record.punchOutTime != null)
          _buildInfoRow('Punch Out', timeFormatter.format(record.punchOutTime!), Icons.logout, AppColors.error),
        if (record.workingHours > 0)
          _buildInfoRow('Working Hours', record.formattedWorkingHours, Icons.access_time, record.isWorkingHoursComplete ? AppColors.success : AppColors.warning),
        if (record.isPunchedOut && !record.isWorkingHoursComplete)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Incomplete working hours. Marked as Absent.',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          )
      ],
    );
  }

  Widget _buildNoRecordInfo(bool isFutureDate) {
    return Text(
      isFutureDate ? 'This is a future date.' : 'No attendance record for this day. Considered as Absent.',
      style: TextStyle(color: isFutureDate ? Theme.of(context).textTheme.bodyMedium?.color : AppColors.error, fontStyle: FontStyle.italic),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text('$label:', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AttendanceRecord? record, bool isFutureDate) {
    final isToday = DateUtils.isSameDay(_selectedDay!, DateTime.now());
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (isToday && (record == null || !record.isPunchedIn))
          ElevatedButton.icon(
            onPressed: () async {
              await _storageService.punchIn(_selectedDay!);
              _loadAttendanceRecords();
            },
            icon: const Icon(Icons.login),
            label: const Text('Punch In'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
          ),
        if (isToday && record != null && record.isPunchedIn && !record.isPunchedOut)
          ElevatedButton.icon(
            onPressed: () async {
              await _storageService.punchOut(_selectedDay!);
              _loadAttendanceRecords();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Punch Out'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
          ),
        if (record == null || (record.status != AttendanceStatus.leave && record.status != AttendanceStatus.weekOff))
          TextButton.icon(
            onPressed: () async {
              await _storageService.markLeaveOrWeekOff(_selectedDay!, AttendanceStatus.leave);
              _loadAttendanceRecords();
            },
            icon: const Icon(Icons.event_busy),
            label: const Text('Mark Leave'),
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
          ),
        if (record == null || (record.status != AttendanceStatus.leave && record.status != AttendanceStatus.weekOff))
          TextButton.icon(
            onPressed: () async {
              await _storageService.markLeaveOrWeekOff(_selectedDay!, AttendanceStatus.weekOff);
              _loadAttendanceRecords();
            },
            icon: const Icon(Icons.weekend),
            label: const Text('Week Off'),
            style: TextButton.styleFrom(foregroundColor: AppColors.weekOff),
          ),
        if (record != null)
          TextButton.icon(
            onPressed: () async {
              final bool confirmDelete = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Deletion'),
                    content: Text('Are you sure you want to delete the attendance record for ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!)}?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false), // User cancels
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true), // User confirms
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              ) ?? false; // Default to false if dialog is dismissed

              if (confirmDelete) {
                await _storageService.deleteAttendanceRecord(_selectedDay!);
                _loadAttendanceRecords();
                _showSuccessSnackBar('Attendance record deleted successfully!');
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).textTheme.bodyMedium?.color),
          ),
      ],
    );
  }

  Widget _buildMonthlySummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
            const Divider(height: 20,),
            _buildStatRow('Present', _presentCount, AppColors.success),
            _buildStatRow('Absent', _absentCount, AppColors.error),
            _buildStatRow('Leave', _leaveCount, AppColors.warning),
            _buildStatRow('Week Off', _weekOffCount, AppColors.weekOff),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(count.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return Icons.check_circle;
      case AttendanceStatus.absent: return Icons.cancel;
      case AttendanceStatus.leave: return Icons.event_busy;
      case AttendanceStatus.weekOff: return Icons.weekend;
    }
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return AppColors.success;
      case AttendanceStatus.absent: return AppColors.error;
      case AttendanceStatus.leave: return AppColors.warning;
      case AttendanceStatus.weekOff: return AppColors.weekOff;
    }
  }
}

extension DateTimeExtension on DateTime {
  DateTime endOfDay() {
    return DateTime(year, month, day, 23, 59, 59, 999, 999);
  }
}
