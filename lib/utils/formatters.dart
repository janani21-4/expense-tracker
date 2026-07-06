import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatDate(DateTime date) {
    final formatter = DateFormat('MMM dd, yyyy');
    return formatter.format(date);
  }

  static String formatDateTime(DateTime date) {
    final formatter = DateFormat('MMM dd, yyyy - hh:mm a');
    return formatter.format(date);
  }
}
