enum AttendanceStatus {
  present,
  absent,
  leave,
  weekOff,
}

extension AttendanceStatusExtension on AttendanceStatus {
  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.leave:
        return 'Leave';
      case AttendanceStatus.weekOff:
        return 'Week Off';
    }
  }
  
  String get value {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.leave:
        return 'leave';
      case AttendanceStatus.weekOff:
        return 'week_off';
    }
  }
  
  static AttendanceStatus fromString(String value) {
    switch (value) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'leave':
        return AttendanceStatus.leave;
      case 'week_off':
        return AttendanceStatus.weekOff;
      default:
        return AttendanceStatus.absent;
    }
  }
}

