import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../models/attendance_status.dart';
import '../utils/app_colors.dart';

class AttendanceDayDetails extends StatelessWidget {
  final DateTime date;
  final AttendanceRecord? record;
  final VoidCallback? onMarkLeave;
  final VoidCallback? onMarkWeekOff;
  final VoidCallback? onDelete;

  const AttendanceDayDetails({
    super.key,
    required this.date,
    this.record,
    this.onMarkLeave,
    this.onMarkWeekOff,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isFutureDate = date.isAfter(DateTime.now());

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateFormatter.format(date),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          if (isToday)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record != null) ...[
              _buildAttendanceInfo(timeFormatter),
            ] else ...[
              _buildNoRecordInfo(isFutureDate),
            ],
          ],
        ),
      ),
      actions: _buildActions(context, isFutureDate),
    );
  }

  Widget _buildAttendanceInfo(DateFormat timeFormatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getStatusBackgroundColor(record!.status),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _getStatusIcon(record!.status),
                color: _getStatusColor(record!.status),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                record!.status.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(record!.status),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        if (record!.status == AttendanceStatus.present) ...[
          // Punch times
          if (record!.punchInTime != null) ...[
            _buildInfoRow(
              'Punch In',
              timeFormatter.format(record!.punchInTime!),
              Icons.login,
              AppColors.success,
            ),
            const SizedBox(height: 8),
          ],
          
          if (record!.punchOutTime != null) ...[
            _buildInfoRow(
              'Punch Out',
              timeFormatter.format(record!.punchOutTime!),
              Icons.logout,
              AppColors.error,
            ),
            const SizedBox(height: 8),
          ],
          
          // Working hours
          if (record!.workingHours > 0) ...[
            _buildInfoRow(
              'Working Hours',
              record!.formattedWorkingHours,
              Icons.access_time,
              record!.isWorkingHoursComplete ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(height: 8),
          ],
          
          // Hours status
          if (record!.isPunchedOut && !record!.isWorkingHoursComplete) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Incomplete working hours (less than 9 hours). This will be marked as AB (Absent).',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        
        if (record!.notes != null && record!.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Notes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            record!.notes!,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNoRecordInfo(bool isFutureDate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFutureDate ? AppColors.surfaceLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFutureDate 
              ? AppColors.textLight.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            isFutureDate ? Icons.schedule : Icons.cancel,
            size: 48,
            color: isFutureDate ? AppColors.textSecondary : AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            isFutureDate 
                ? 'Future Date'
                : 'No Attendance Record',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isFutureDate ? AppColors.textSecondary : AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFutureDate
                ? 'This date hasn\'t occurred yet.'
                : 'No punch in/out recorded for this date. This will be considered as absent unless marked as leave or week off.',
            style: TextStyle(
              fontSize: 14,
              color: isFutureDate ? AppColors.textLight : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context, bool isFutureDate) {
    final actions = <Widget>[];
    
    // Cancel button
    actions.add(
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    );
    
    // Don't show action buttons for future dates
    if (isFutureDate) {
      return actions;
    }
    
    // Delete button (only if record exists)
    if (record != null && onDelete != null) {
      actions.insert(0, TextButton(
        onPressed: () {
          _showDeleteConfirmation(context);
        },
        style: TextButton.styleFrom(foregroundColor: AppColors.error),
        child: const Text('Delete'),
      ));
    }
    
    // Mark Leave button (only if no record or not already on leave)
    if ((record == null || record!.status != AttendanceStatus.leave) && onMarkLeave != null) {
      actions.insert(0, TextButton(
        onPressed: onMarkLeave,
        style: TextButton.styleFrom(foregroundColor: AppColors.warning),
        child: const Text('Mark Leave'),
      ));
    }
    
    // Mark Week Off button (only if no record or not already week off)
    if ((record == null || record!.status != AttendanceStatus.weekOff) && onMarkWeekOff != null) {
      actions.insert(0, TextButton(
        onPressed: onMarkWeekOff,
        style: TextButton.styleFrom(foregroundColor: AppColors.calendarWeekOff),
        child: const Text('Week Off'),
      ));
    }
    
    return actions;
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this attendance record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close confirmation dialog
              if (onDelete != null) {
                onDelete!();
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
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

  Color _getStatusBackgroundColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.successLight;
      case AttendanceStatus.absent:
        return AppColors.errorLight;
      case AttendanceStatus.leave:
        return AppColors.warningLight;
      case AttendanceStatus.weekOff:
        return AppColors.calendarWeekOff.withOpacity(0.1);
    }
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.leave:
        return Icons.event_busy;
      case AttendanceStatus.weekOff:
        return Icons.weekend;
    }
  }
}

