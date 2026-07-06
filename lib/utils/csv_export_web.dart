// Web-specific CSV export using dart:html
import 'dart:html' as html;

class CsvExportHelper {
  static Future<void> exportCSV(String csvData, String fileName) async {
    final blob = html.Blob([csvData], 'text/csv;charset=utf-8;');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
