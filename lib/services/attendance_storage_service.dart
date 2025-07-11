import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_record.dart';
import '../models/attendance_status.dart';

class AttendanceStorageService {
  static const String _attendanceKey = 'attendance_records';
  static const String _activePunchInTimeKey = 'active_punch_in_time';
  static const String _standardWorkingHoursKey = 'standard_working_hours';
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

  // Check if the given date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  // Check if the given date is in the past
  bool _isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isBefore(today);
  }

  // Validate date for punching operations
  bool _validatePunchDate(DateTime date) {
    // For this app, we are only allowing today's date for punching
    if (!_isToday(date)) {
        return false;
    }
    return true;
  }

  // Save attendance record
  Future<bool> saveAttendanceRecord(AttendanceRecord record) async {
    await init();
    try {
      final records = await getAllAttendanceRecords();
      
      records.removeWhere((r) => r.dateKey == record.dateKey);
      records.add(record);
      
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
      
      final matchingRecords = records.where((record) => record.dateKey == dateKey);
      if (matchingRecords.isNotEmpty) {
        return matchingRecords.first;
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

  // Punch in with date validation and optional manual time
  Future<bool> punchIn(DateTime date, {DateTime? punchTime}) async {
    try {
      if (!_validatePunchDate(date)) {
        throw Exception('Cannot punch in for past dates. Please punch in for today only.');
      }

      final existingRecord = await getAttendanceRecord(date);
      final standardHours = await getStandardWorkingHours();
      
      if (existingRecord != null && existingRecord.isPunchedIn) {
        throw Exception('You have already punched in for today.');
      }
      
      final record = AttendanceRecord(
        date: DateTime(date.year, date.month, date.day),
        punchInTime: punchTime ?? DateTime.now(), // Use manual time if provided
        status: AttendanceStatus.present,
        standardWorkingHours: standardHours,
      );
      
      final result = await saveAttendanceRecord(record);
      if (result) {
        await _prefs!.setString(_activePunchInTimeKey, record.punchInTime!.toIso8601String());
      }
      return result;
    } catch (e) {
      print('Error punching in: $e');
      rethrow;
    }
  }

  // Punch out with date validation and optional manual time
  Future<bool> punchOut(DateTime date, {DateTime? punchTime}) async {
    try {
      if (!_validatePunchDate(date)) {
        throw Exception('Cannot punch out for past dates. Please punch out for today only.');
      }

      final existingRecord = await getAttendanceRecord(date);
      
      if (existingRecord == null || !existingRecord.isPunchedIn) {
        throw Exception('You must punch in first before punching out.');
      }
      
      if (existingRecord.isPunchedOut) {
        throw Exception('You have already punched out for today.');
      }
      
      DateTime punchOutTime = punchTime ?? DateTime.now(); // Use manual time if provided
      
      // Additional validation for manual time
      if (punchOutTime.isBefore(existingRecord.punchInTime!)) {
        throw Exception('Punch-out time cannot be earlier than punch-in time.');
      }

      AttendanceStatus finalStatus = AttendanceStatus.present;

      final duration = punchOutTime.difference(existingRecord.punchInTime!); 
      final double workingHours = duration.inMinutes / 60.0;

      if (workingHours < await getStandardWorkingHours()) {
        finalStatus = AttendanceStatus.absent;
      }

      final updatedRecord = existingRecord.copyWith(
        punchOutTime: punchOutTime,
        status: finalStatus,
      );
      
      final result = await saveAttendanceRecord(updatedRecord);
      if (result) {
        await _prefs!.remove(_activePunchInTimeKey);
      }
      return result;
    } catch (e) {
      print('Error punching out: $e');
      rethrow;
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

  String getPastDateErrorMessage() {
    return 'Past date punching is not allowed. You can only punch in/out for today.';
  }

  bool isPunchingAllowed(DateTime date) {
    return _isToday(date) && !_isPastDate(date);
  }

  // Get active punch in time
  Future<DateTime?> getActivePunchInTime() async {
    await init();
    final punchInTimeString = _prefs!.getString(_activePunchInTimeKey);
    if (punchInTimeString != null) {
      return DateTime.parse(punchInTimeString);
    }
    return null;
  }

  // Save standard working hours
  Future<bool> saveStandardWorkingHours(double hours) async {
    await init();
    return await _prefs!.setDouble(_standardWorkingHoursKey, hours);
  }

  // Get standard working hours
  Future<double> getStandardWorkingHours() async {
    await init();
    return _prefs!.getDouble(_standardWorkingHoursKey) ?? 9.0; // Default to 9 hours
  }
}

