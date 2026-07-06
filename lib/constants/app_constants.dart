import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Expense Tracker';
  
  // Expense Categories
  static const List<String> categories = [
    'All',
    'Food',
    'Rent',
    'EMI',
    'Loan',
    'Shopping',
    'Transport',
    'Bills',
    'Others',
  ];

  // Category Colors
  static const Map<String, Color> categoryColors = {
    'All': Color(0xFF6C5CE7),
    'Food': Color(0xFFFF6B6B),
    'Rent': Color(0xFF4ECDC4),
    'EMI': Color(0xFF45B7D1),
    'Loan': Color(0xFF96CEB4),
    'Shopping': Color(0xFFFFEEAD),
    'Transport': Color(0xFFD4A5A5),
    'Bills': Color(0xFF9B59B6),
    'Others': Color(0xFF95A5A6),
  };

  // Category Icons
  static const Map<String, IconData> categoryIcons = {
    'All': Icons.apps,
    'Food': Icons.restaurant,
    'Rent': Icons.home,
    'EMI': Icons.account_balance,
    'Loan': Icons.money,
    'Shopping': Icons.shopping_bag,
    'Transport': Icons.directions_car,
    'Bills': Icons.receipt_long,
    'Others': Icons.category,
  };

  // Storage Keys
  static const String expensesKey = 'expenses';
}
