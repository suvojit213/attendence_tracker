import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../models/attendance_status.dart';
import '../utils/app_colors.dart';

class AttendanceSummaryCard extends StatelessWidget {
  final AttendanceRecord? record;
  final VoidCallback? onRefresh;

  const AttendanceSummaryCard({
    super.key,
    this.record,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Attendance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                    iconSize: 20,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (record == null) ...[
              _buildEmptyState(),
            ] else ...[
              _buildAttendanceDetails(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.schedule,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'No attendance record for today',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please punch in to start tracking your attendance',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceDetails() {
    final timeFormatter = DateFormat('h:mm a');
    
    return Column(
      children: [
        // Status indicator
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(record!.status),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Time details
        if (record!.status == AttendanceStatus.present) ...[
          Row(
            children: [
              Expanded(
                child: _buildTimeInfo(
                  'Punch In',
                  record!.punchInTime != null 
                      ? timeFormatter.format(record!.punchInTime!)
                      : 'Not punched in',
                  Icons.login,
                  record!.punchInTime != null ? AppColors.success : AppColors.textLight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeInfo(
                  'Punch Out',
                  record!.punchOutTime != null 
                      ? timeFormatter.format(record!.punchOutTime!)
                      : 'Not punched out',
                  Icons.logout,
                  record!.punchOutTime != null ? AppColors.error : AppColors.textLight,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Working hours
          if (record!.workingHours > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: record!.isWorkingHoursComplete 
                    ? AppColors.successLight 
                    : AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: record!.isWorkingHoursComplete 
                            ? AppColors.success 
                            : AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Working Hours',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: record!.isWorkingHoursComplete 
                              ? AppColors.success 
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    record!.formattedWorkingHours,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: record!.isWorkingHoursComplete 
                          ? AppColors.success 
                          : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
            
            // Progress bar
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress to 9 hours',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${(record!.workingHours / 9 * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (record!.workingHours / 9).clamp(0.0, 1.0),
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    record!.isWorkingHoursComplete 
                        ? AppColors.success 
                        : AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
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

