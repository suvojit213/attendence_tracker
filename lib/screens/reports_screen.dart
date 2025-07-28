import 'dart:io';

import 'package:attendance_tracker/models/attendance_record.dart';
import 'package:attendance_tracker/models/attendance_status.dart';
import 'package:attendance_tracker/services/attendance_storage_service.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final AttendanceStorageService _storageService =
      AttendanceStorageService.instance;

  Future<void> _generatePdfReport() async {
    final records = await _storageService.getAllAttendanceRecords();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Attendance Report',
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

    final output = await getDownloadsDirectory();
    final file = File('${output?.path}/attendance_report.pdf');
    await file.writeAsBytes(await pdf.save());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF report saved to ${file.path}'),
      ),
    );
  }

  Future<void> _generateCsvReport() async {
    final records = await _storageService.getAllAttendanceRecords();
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
    final output = await getDownloadsDirectory();
    final file = File('${output?.path}/attendance_report.csv');
    await file.writeAsString(csv);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV report saved to ${file.path}'),
      ),
    );
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