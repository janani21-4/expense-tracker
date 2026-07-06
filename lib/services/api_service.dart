import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expense.dart';
import '../models/budget.dart';

/// API Service for communicating with the FastAPI backend
/// Base URL for local testing
const String baseUrl = 'http://127.0.0.1:8000';

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // =========================
  // EXPENSE API METHODS
  // =========================

  /// Get all expenses from the backend
  Future<List<Expense>> getExpenses() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/expenses'),
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Expense.fromJson(json)).toList();
      } else {
        print('Failed to load expenses: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching expenses: $e');
      return [];
    }
  }

  /// Add a new expense to the backend
  Future<Expense?> addExpense(Expense expense) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/expenses'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(expense.toJson()),
      );

      if (response.statusCode == 200) {
        return Expense.fromJson(json.decode(response.body));
      } else {
        print('Failed to add expense: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error adding expense: $e');
      return null;
    }
  }

  /// Update an existing expense in the backend
  Future<Expense?> updateExpense(Expense expense) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/expenses/${expense.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(expense.toJson()),
      );

      if (response.statusCode == 200) {
        return Expense.fromJson(json.decode(response.body));
      } else {
        print('Failed to update expense: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error updating expense: $e');
      return null;
    }
  }

  /// Delete an expense from the backend
  Future<bool> deleteExpense(int expenseId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/expenses/$expenseId'),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to delete expense: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting expense: $e');
      return false;
    }
  }

  // =========================
  // BUDGET API METHODS
  // =========================

  /// Get all budgets from the backend
  Future<List<Budget>> getBudgets() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/budget'),
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Budget.fromJson(json)).toList();
      } else {
        print('Failed to load budgets: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching budgets: $e');
      return [];
    }
  }

  /// Create or update a budget in the backend
  Future<Budget?> createOrUpdateBudget(Budget budget) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/budget'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'month': budget.month,
          'amount': budget.amount,
        }),
      );

      if (response.statusCode == 200) {
        return Budget.fromJson(json.decode(response.body));
      } else {
        print('Failed to create/update budget: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error creating/updating budget: $e');
      return null;
    }
  }
}
