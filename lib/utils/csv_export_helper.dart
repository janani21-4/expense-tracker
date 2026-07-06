// Abstract class for CSV export - platform-specific implementations
abstract class CsvExportHelper {
  static Future<dynamic> exportCSV(String csvData, String fileName) {
    throw UnimplementedError('Platform-specific implementation not loaded');
  }
}
