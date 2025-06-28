import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_record.dart';
import '../models/attendance_status.dart';

class AttendanceStorageService {
  static const String _attendanceKey = 'attendance_records';
  static AttendanceStorageService? _instance;
  SharedPreferences? _prefs;

  AttendanceStorageService._();

  static AttendanceStorageService get instance {
    _instance ??= AttendanceStorageService._();
    return _instance!;
  }

  // Initialize shared preferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Save attendance record
  Future<bool> saveAttendanceRecord(AttendanceRecord record) async {
    await init();
    try {
      final records = await getAllAttendanceRecords();
      
      // Remove existing record for the same date if any
      records.removeWhere((r) => r.dateKey == record.dateKey);
      
      // Add new record
      records.add(record);
      
      // Convert to JSON and save
      final jsonList = records.map((r) => r.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      return await _prefs!.setString(_attendanceKey, jsonString);
    } catch (e) {
      print('Error saving attendance record: $e');
      return false;
    }
  }

  // Get attendance record for specific date
  Future<AttendanceRecord?> getAttendanceRecord(DateTime date) async {
    await init();
    try {
      final records = await getAllAttendanceRecords();
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      for (final record in records) {
        if (record.dateKey == dateKey) {
          return record;
        }
      }
      return null;
    } catch (e) {
      print('Error getting attendance record: $e');
      return null;
    }
  }

  // Get all attendance records
  Future<List<AttendanceRecord>> getAllAttendanceRecords() async {
    await init();
    try {
      final jsonString = _prefs!.getString(_attendanceKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => AttendanceRecord.fromJson(json)).toList();
    } catch (e) {
      print('Error getting all attendance records: $e');
      return [];
    }
  }

  // Get attendance records for a specific month
  Future<List<AttendanceRecord>> getAttendanceRecordsForMonth(int year, int month) async {
    await init();
    try {
      final allRecords = await getAllAttendanceRecords();
      return allRecords.where((record) {
        return record.date.year == year && record.date.month == month;
      }).toList();
    } catch (e) {
      print('Error getting attendance records for month: $e');
      return [];
    }
  }

  // Punch in
  Future<bool> punchIn(DateTime date) async {
    try {
      final existingRecord = await getAttendanceRecord(date);
      
      if (existingRecord != null && existingRecord.isPunchedIn) {
        return false; // Already punched in
      }
      
      final record = AttendanceRecord(
        date: DateTime(date.year, date.month, date.day),
        punchInTime: DateTime.now(),
        status: AttendanceStatus.present,
      );
      
      return await saveAttendanceRecord(record);
    } catch (e) {
      print('Error punching in: $e');
      return false;
    }
  }

  // Punch out
  Future<bool> punchOut(DateTime date) async {
    try {
      final existingRecord = await getAttendanceRecord(date);
      
      if (existingRecord == null || !existingRecord.isPunchedIn) {
        return false; // Must punch in first
      }
      
      if (existingRecord.isPunchedOut) {
        return false; // Already punched out
      }
      
      DateTime punchOutTime = DateTime.now();
      AttendanceStatus finalStatus = AttendanceStatus.present;

      // Calculate working hours to determine final status
      // Adjust punchOutTime for overnight shifts for calculation
      DateTime effectivePunchOutTime = punchOutTime;
      if (punchOutTime.isBefore(existingRecord.punchInTime!)) {
        effectivePunchOutTime = punchOutTime.add(const Duration(days: 1));
      }
      final duration = effectivePunchOutTime.difference(existingRecord.punchInTime!); 
      final double workingHours = duration.inMinutes / 60.0;

      // If working hours are less than 1 minute, mark as absent
      if (workingHours * 60 < 1) {
        finalStatus = AttendanceStatus.absent;
      } else if (workingHours < 9.0) {
        finalStatus = AttendanceStatus.absent;
      }

      final updatedRecord = existingRecord.copyWith(
        punchOutTime: punchOutTime,
        status: finalStatus,
      );
      
      // Determine the effective date for the attendance record
      // If punch-out is on the next day but within a reasonable overnight shift window (e.g., before 6 AM),
      // consider it for the punch-in date.
      DateTime effectiveDate = existingRecord.date;
      if (updatedRecord.punchInTime != null && updatedRecord.punchOutTime != null) {
        if (updatedRecord.punchOutTime!.isBefore(updatedRecord.punchInTime!)) {
          // This means punch-out is on the next day
          // Check if the punch-out is early morning (e.g., before 6 AM) of the next day
          if (updatedRecord.punchOutTime!.hour < 6) {
            effectiveDate = existingRecord.date; // Keep the original punch-in date
          } else {
            effectiveDate = updatedRecord.punchOutTime!; // Use the punch-out date
          }
        } else if (updatedRecord.punchOutTime!.day != existingRecord.date.day) {
          // If punch-out is on a different day but not before punch-in (e.g., 3 PM to 3 PM next day)
          // This case might need more specific handling based on shift definitions.
          // For now, if it's a new day, use the punch-out date.
          effectiveDate = updatedRecord.punchOutTime!;
        }
      }

      final finalRecord = updatedRecord.copyWith(date: DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day));
      
      return await saveAttendanceRecord(finalRecord);
    } catch (e) {
      print('Error punching out: $e');
      return false;
    }
  }

  // Mark leave or week off
  Future<bool> markLeaveOrWeekOff(DateTime date, AttendanceStatus status) async {
    try {
      if (status != AttendanceStatus.leave && status != AttendanceStatus.weekOff) {
        return false;
      }
      
      final record = AttendanceRecord(
        date: DateTime(date.year, date.month, date.day),
        punchInTime: null,
        punchOutTime: null,
        status: status,
      );
      
      return await saveAttendanceRecord(record);
    } catch (e) {
      print('Error marking leave/week off: $e');
      return false;
    }
  }

  // Delete attendance record
  Future<bool> deleteAttendanceRecord(DateTime date) async {
    await init();
    try {
      final records = await getAllAttendanceRecords();
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      records.removeWhere((r) => r.dateKey == dateKey);
      
      final jsonList = records.map((r) => r.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      return await _prefs!.setString(_attendanceKey, jsonString);
    } catch (e) {
      print('Error deleting attendance record: $e');
      return false;
    }
  }
}


