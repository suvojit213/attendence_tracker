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
      
      final updatedRecord = existingRecord.copyWith(
        punchOutTime: DateTime.now(),
      );
      
      return await saveAttendanceRecord(updatedRecord);
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

  // Clear all records (for testing/reset)
  Future<bool> clearAllRecords() async {
    await init();
    try {
      return await _prefs!.remove(_attendanceKey);
    } catch (e) {
      print('Error clearing all records: $e');
      return false;
    }
  }
}

