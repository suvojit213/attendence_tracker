import 'dart:convert';
import 'attendance_status.dart';

class AttendanceRecord {
  final DateTime date;
  final DateTime? punchInTime;
  final DateTime? punchOutTime;
  final AttendanceStatus status;
  final String? notes;

  AttendanceRecord({
    required this.date,
    this.punchInTime,
    this.punchOutTime,
    required this.status,
    this.notes,
  });

  // Calculate working hours
  double get workingHours {
    if (punchInTime != null && punchOutTime != null) {
      // Adjust punchOutTime for overnight shifts
      DateTime effectivePunchOutTime = punchOutTime!;
      if (punchOutTime!.isBefore(punchInTime!)) {
        effectivePunchOutTime = punchOutTime!.add(const Duration(days: 1));
      }
      final duration = effectivePunchOutTime.difference(punchInTime!);
      return duration.inMinutes / 60.0;
    }
    return 0.0;
  }

  // Check if working hours are complete (9 hours)
  bool get isWorkingHoursComplete {
    return workingHours >= 9.0;
  }

  // Check if punch in is done
  bool get isPunchedIn {
    return punchInTime != null;
  }

  // Check if punch out is done
  bool get isPunchedOut {
    return punchOutTime != null;
  }

  // Get formatted working hours
  String get formattedWorkingHours {
    final hours = workingHours.floor();
    final minutes = ((workingHours - hours) * 60).round();
    return '${hours}h ${minutes}m';
  }

  // Get date key for storage
  String get dateKey {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'punchInTime': punchInTime?.toIso8601String(),
      'punchOutTime': punchOutTime?.toIso8601String(),
      'status': status.value,
      'notes': notes,
    };
  }

  // Create from JSON
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: DateTime.parse(json['date']),
      punchInTime: json['punchInTime'] != null 
          ? DateTime.parse(json['punchInTime']) 
          : null,
      punchOutTime: json['punchOutTime'] != null 
          ? DateTime.parse(json['punchOutTime']) 
          : null,
      status: AttendanceStatusExtension.fromString(json['status']),
      notes: json['notes'],
    );
  }

  // Create copy with updated values
  AttendanceRecord copyWith({
    DateTime? date,
    DateTime? punchInTime,
    DateTime? punchOutTime,
    AttendanceStatus? status,
    String? notes,
  }) {
    return AttendanceRecord(
      date: date ?? this.date,
      punchInTime: punchInTime ?? this.punchInTime,
      punchOutTime: punchOutTime ?? this.punchOutTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'AttendanceRecord(date: $date, punchIn: $punchInTime, punchOut: $punchOutTime, status: $status)';
  }
}


