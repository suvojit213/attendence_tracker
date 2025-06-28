# Attendance Tracker App

A beautiful Flutter attendance tracking app with punch in/out functionality, calendar view, and leave management.

## Features

- **Punch In/Out**: Easy punch in and punch out with automatic date/time filling
- **Validation**: Punch in is mandatory before punch out, only one punch in/out per day
- **Calendar View**: Visual calendar showing attendance status with color coding
- **Working Hours Tracking**: Automatic calculation of working hours
- **Leave Management**: Mark days as leave or week off from the calendar
- **Beautiful UI**: Modern, clean design with gradient colors and smooth animations

## Color Coding

- 🟢 **Green**: Present with complete hours (9+ hours)
- 🔴 **Red**: Absent or incomplete hours (less than 9 hours) - marked as AB
- 🟠 **Orange**: On leave
- 🟣 **Purple**: Week off

## How to Run

1. Make sure you have Flutter installed on your system
2. Navigate to the project directory:
   ```bash
   cd attendance_tracker_app
   ```
3. Get dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── attendance_record.dart
│   └── attendance_status.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   └── calendar_screen.dart
├── widgets/                  # Reusable widgets
│   ├── punch_button.dart
│   ├── attendance_summary_card.dart
│   └── attendance_day_details.dart
├── services/                 # Business logic
│   └── attendance_storage_service.dart
└── utils/                    # Utilities
    └── app_colors.dart
```

## Dependencies

- `shared_preferences`: Local data storage
- `table_calendar`: Calendar widget
- `intl`: Date/time formatting
- `flutter_local_notifications`: Future notifications support

## Usage Instructions

### Home Screen
- View today's date, time, and attendance status
- Punch in to start tracking attendance
- Punch out to complete the day (only after punch in)
- View working hours and completion status

### Calendar Screen
- View monthly attendance overview
- Tap on any date to see details
- Mark past dates as leave or week off
- Red dots indicate absent or incomplete hours
- Green dots indicate present with complete hours

### Attendance Rules
1. Must punch in before punch out
2. Only one punch in/out per day
3. Working day requires 9+ hours to be considered complete
4. Incomplete hours are marked as AB (Absent)
5. Future dates cannot be modified

## Data Storage

All attendance data is stored locally on the device using SharedPreferences. Data persists between app sessions.

## Support

This app works offline and doesn't require internet connection. All data is stored locally on your device.

