import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../widgets/expense_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/budget_card.dart';
import '../constants/app_constants.dart';
import 'add_expense_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ExpenseService _expenseService = ExpenseService.instance;
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  double _totalAmount = 0.0;
  double _monthlyBudget = 0.0;
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    final allExpenses = await _expenseService.getExpenses();
    
    // Filter expenses by selected month
    final monthExpenses = allExpenses.where((expense) {
      return expense.date.year == _selectedMonth.year &&
          expense.date.month == _selectedMonth.month;
    }).toList();

    final monthTotal = monthExpenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amount,
    );

    // Load budget for selected month
    final budget = await _expenseService.getBudget(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    setState(() {
      _expenses = monthExpenses;
      _filteredExpenses = monthExpenses;
      _totalAmount = monthTotal;
      _monthlyBudget = budget ?? 0.0;
      _isLoading = false;
    });
  }

  Future<void> _deleteExpense(String expenseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _expenseService.deleteExpense(expenseId);
      await _loadExpenses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted')),
        );
      }
    }
  }

  void _filterExpenses() {
    setState(() {
      _filteredExpenses = _expenses.where((expense) {
        final matchesSearch = _searchQuery.isEmpty ||
            expense.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (expense.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            expense.amount.toString().contains(_searchQuery);
        
        final matchesCategory = _selectedCategoryFilter == 'All' ||
            expense.category == _selectedCategoryFilter;
        
        final matchesDateRange = _startDate == null && _endDate == null ||
            (_startDate != null && _endDate != null &&
             expense.date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
             expense.date.isBefore(_endDate!.add(const Duration(days: 1))));
        
        return matchesSearch && matchesCategory && matchesDateRange;
      }).toList();
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year + (_selectedMonth.month + offset - 1) ~/ 12,
        (_selectedMonth.month + offset - 1) % 12 + 1,
        1,
      );
    });
    _loadExpenses();
  }

  String _getMonthName() {
    return DateFormat('MMMM yyyy').format(_selectedMonth);
  }

  void _showBudgetDialog() async {
    final budgetController = TextEditingController(text: _monthlyBudget > 0 ? _monthlyBudget.toString() : '');
    
    final result = await showDialog<Object?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: budgetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Budget Amount',
            hintText: 'Enter amount',
            prefixIcon: Icon(Icons.currency_rupee),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          if (_monthlyBudget > 0)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'clear'),
              child: const Text('Clear'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(budgetController.text);
              if (amount != null && amount > 0) {
                Navigator.pop(dialogContext, amount);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == 'clear' && mounted) {
      await _expenseService.clearBudget(_selectedMonth.year, _selectedMonth.month);
      await _loadExpenses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget cleared')),
        );
      }
    } else if (result is double && mounted) {
      await _expenseService.setBudget(_selectedMonth.year, _selectedMonth.month, result);
      await _loadExpenses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget saved successfully')),
        );
      }
    }
  }

  void _navigateToAddExpense([Expense? expense]) async {
    final isEdit = expense != null;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddExpenseScreen(expense: expense)),
    );
    
    if (result == true && mounted) {
      await _loadExpenses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Expense updated' : 'Expense added'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (mounted) {
      await _loadExpenses();
    }
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _filterExpenses();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _filterExpenses();
  }

  Future<void> _exportToCSV() async {
    if (_filteredExpenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No expenses to export')),
      );
      return;
    }

    try {
      final rows = [
        ['Title', 'Category', 'Amount', 'Date', 'Description'],
        ..._filteredExpenses.map((expense) => [
          expense.title,
          expense.category,
          expense.amount.toString(),
          DateFormat('MMM dd, yyyy').format(expense.date),
          expense.description ?? '',
        ]),
      ];

      final csvData = const ListToCsvConverter().convert(rows);
      final monthName = DateFormat('MMMM_yyyy').format(_selectedMonth);
      final fileName = 'expenses_$monthName.csv';
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to ${file.path}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToCSV,
            tooltip: 'Export CSV',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
              );
            },
            tooltip: 'Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      AnimatedOpacity(
                        opacity: _isLoading ? 0 : 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: SummaryCard(
                          totalAmount: _totalAmount,
                          expenseCount: _expenses.length,
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: _isLoading ? 0 : 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: BudgetCard(
                          budget: _monthlyBudget,
                          spent: _totalAmount,
                          onSetBudget: _showBudgetDialog,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () => _changeMonth(-1),
                              tooltip: 'Previous Month',
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  _getMonthName(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => _changeMonth(1),
                              tooltip: 'Next Month',
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by category, notes, or amount...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                      _filterExpenses();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                            _filterExpenses();
                          },
                        ),
                      ),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: AppConstants.categories.length,
                          itemBuilder: (context, index) {
                            final category = AppConstants.categories[index];
                            final isSelected = category == _selectedCategoryFilter;
                            final color = AppConstants.categoryColors[category] ??
                                          AppConstants.categoryColors['All']!;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategoryFilter = category;
                                  });
                                  _filterExpenses();
                                },
                                selectedColor: color.withValues(alpha: 0.3),
                                checkmarkColor: color,
                                labelStyle: TextStyle(
                                  color: isSelected ? color : Colors.grey[700],
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color: isSelected ? color : Colors.grey[300]!,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showDateRangePicker,
                                icon: const Icon(Icons.calendar_month),
                                label: Text(
                                  _startDate != null && _endDate != null
                                      ? '${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}'
                                      : 'Filter by Date Range',
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            if (_startDate != null && _endDate != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearDateFilter,
                                tooltip: 'Clear Date Filter',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_filteredExpenses.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: Icon(
                                _expenses.isEmpty 
                                    ? Icons.account_balance_wallet_outlined
                                    : Icons.search_off,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _expenses.isEmpty
                                  ? 'No expenses in ${_getMonthName()}'
                                  : 'No matching expenses',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _expenses.isEmpty
                                  ? 'Start tracking your expenses by adding your first one'
                                  : 'Try adjusting your search, category filter, or date range',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_expenses.isEmpty) ...[
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => _navigateToAddExpense(),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Expense'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final expense = _filteredExpenses[index];
                          return TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 300),
                            tween: Tween(begin: 0, end: 1),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: ExpenseCard(
                                      expense: expense,
                                      onDelete: () => _deleteExpense(expense.id),
                                      onTap: () => _navigateToAddExpense(expense),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        childCount: _filteredExpenses.length,
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddExpense(),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}
