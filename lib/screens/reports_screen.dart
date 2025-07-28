import 'dart:io';
import 'dart:typed_data';

import 'package:attendance_tracker/models/attendance_record.dart';
import 'package:attendance_tracker/models/attendance_status.dart';
import 'package:attendance_tracker/services/attendance_storage_service.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for MethodChannel
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const platform = MethodChannel('com.example.attendance_tracker/reports');

  final AttendanceStorageService _storageService =
      AttendanceStorageService.instance;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _saveFileNative(String fileName, Uint8List fileBytes) async {
    try {
      final String? result = await platform.invokeMethod(
        'saveFileToDocuments',
        {'fileName': fileName, 'fileBytes': fileBytes},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved to: $result'),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save report: ${e.message}'),
          ),
        );
      }
    }
  }

  Future<void> _generatePdfReport() async {
    final records = await _storageService.getAttendanceRecordsForMonth(
        _selectedYear, _selectedMonth);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                  'Attendance Report - ${getMonthName(_selectedMonth)} $_selectedYear',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Table.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['Date', 'Status', 'Punch In', 'Punch Out', 'Working Hours'],
                ...records.map((record) => [
                      record.date.toIso8601String().substring(0, 10),
                      record.status.displayName,
                      record.punchInTime?.toIso8601String() ?? 'N/A',
                      record.punchOutTime?.toIso8601String() ?? 'N/A',
                      record.formattedWorkingHours,
                    ]),
              ],
            ),
          ];
        },
      ),
    );

    final fileName = 'attendance_report_${_selectedYear}_${_selectedMonth}.pdf';
    final pdfBytes = await pdf.save();
    await _saveFileNative(fileName, Uint8List.fromList(pdfBytes));
  }

  Future<void> _generateCsvReport() async {
    final records = await _storageService.getAttendanceRecordsForMonth(
        _selectedYear, _selectedMonth);
    final List<List<dynamic>> rows = [];

    rows.add(['Date', 'Status', 'Punch In', 'Punch Out', 'Working Hours']);
    for (var record in records) {
      rows.add([
        record.date.toIso8601String().substring(0, 10),
        record.status.displayName,
        record.punchInTime?.toIso8601String() ?? 'N/A',
        record.punchOutTime?.toIso8601String() ?? 'N/A',
        record.formattedWorkingHours,
      ]);
    }

    final String csv = const ListToCsvConverter().convert(rows);
    final fileName = 'attendance_report_${_selectedYear}_${_selectedMonth}.csv';
    await _saveFileNative(fileName, Uint8List.fromList(csv.codeUnits));
  }

  String getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Reports'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<int>(
                  value: _selectedMonth,
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedMonth = newValue;
                      });
                    }
                  },
                  items: List.generate(12, (index) => index + 1)
                      .map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(getMonthName(value)),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 20),
                DropdownButton<int>(
                  value: _selectedYear,
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedYear = newValue;
                      });
                    }
                  },
                  items: List.generate(5, (index) => DateTime.now().year - 2 + index)
                      .map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _generatePdfReport,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Download as PDF'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _generateCsvReport,
              icon: const Icon(Icons.table_chart),
              label: const Text('Download as CSV'),
            ),
          ],
        ),
      ),
    );
  }
}