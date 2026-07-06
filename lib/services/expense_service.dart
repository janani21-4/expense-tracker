import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../constants/app_constants.dart';

class ExpenseService {
  static ExpenseService? _instance;
  static ExpenseService get instance => _instance ??= ExpenseService._();
  
  ExpenseService._();

  Future<List<Expense>> getExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getString(AppConstants.expensesKey);
    
    if (expensesJson == null) return [];
    
    final List<dynamic> decoded = json.decode(expensesJson);
    return decoded.map((json) => Expense.fromJson(json)).toList();
  }

  Future<void> addExpense(Expense expense) async {
    final expenses = await getExpenses();
    expenses.add(expense);
    await _saveExpenses(expenses);
  }

  Future<void> deleteExpense(String expenseId) async {
    final expenses = await getExpenses();
    expenses.removeWhere((expense) => expense.id == expenseId);
    await _saveExpenses(expenses);
  }

  Future<void> updateExpense(Expense updatedExpense) async {
    final expenses = await getExpenses();
    final index = expenses.indexWhere((expense) => expense.id == updatedExpense.id);
    
    if (index != -1) {
      expenses[index] = updatedExpense;
      await _saveExpenses(expenses);
    }
  }

  Future<double> getTotalExpenses() async {
    final expenses = await getExpenses();
    return expenses.fold<double>(
      0.0,
      (double sum, Expense expense) => sum + expense.amount,
    );
  }

  Future<Map<String, double>> getExpensesByCategory() async {
    final expenses = await getExpenses();
    final Map<String, double> categoryTotals = {};
    
    for (final expense in expenses) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    
    return categoryTotals;
  }

  Future<void> _saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = json.encode(expenses.map((e) => e.toJson()).toList());
    await prefs.setString(AppConstants.expensesKey, expensesJson);
  }

  // Budget Management
  String _getBudgetKey(int year, int month) {
    return 'budget_$year-$month';
  }

  Future<double?> getBudget(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_getBudgetKey(year, month));
  }

  Future<void> setBudget(int year, int month, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_getBudgetKey(year, month), amount);
  }

  Future<void> clearBudget(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getBudgetKey(year, month));
  }
}
