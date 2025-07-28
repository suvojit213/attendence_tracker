import 'package:flutter/material.dart';
import 'package:csv/csv.dart';

class CsvViewerScreen extends StatelessWidget {
  final String csvContent;
  final String title;

  const CsvViewerScreen({super.key, required this.csvContent, this.title = 'CSV Viewer'});

  @override
  Widget build(BuildContext context) {
    final List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(csvContent);

    if (rowsAsListOfValues.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: const Center(child: Text('No data to display.')),
      );
    }

    final List<dynamic> headers = rowsAsListOfValues.first;
    final List<List<dynamic>> dataRows = rowsAsListOfValues.sublist(1);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: headers.map((header) => DataColumn(label: Text(header.toString(), style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
            rows: dataRows.map((row) => DataRow(cells: row.map((cell) => DataCell(Text(cell.toString()))).toList())).toList(),
          ),
        ),
      ),
    );
  }
}