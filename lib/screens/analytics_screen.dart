import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/expense_service.dart';
import '../utils/formatters.dart';
import '../constants/app_constants.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ExpenseService _expenseService = ExpenseService.instance;
  DateTime _month1 = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _month2 = DateTime(
    DateTime.now().year,
    DateTime.now().month == 1 ? 12 : DateTime.now().month - 1,
    1,
  );
  bool _isLoading = true;
  double _month1Total = 0.0;
  double _month2Total = 0.0;
  int _month1Count = 0;
  int _month2Count = 0;
  Map<String, double> _categoryTotals = {};
  int _selectedCategoryIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final expenses = await _expenseService.getExpenses();

    final month1Expenses = expenses.where((expense) {
      return expense.date.year == _month1.year &&
          expense.date.month == _month1.month;
    }).toList();

    final month2Expenses = expenses.where((expense) {
      return expense.date.year == _month2.year &&
          expense.date.month == _month2.month;
    }).toList();

    // Calculate category totals from all expenses
    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      final category = expense.category;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + expense.amount;
    }

    setState(() {
      _month1Total = month1Expenses.fold<double>(
        0.0,
        (sum, expense) => sum + expense.amount,
      );
      _month2Total = month2Expenses.fold<double>(
        0.0,
        (sum, expense) => sum + expense.amount,
      );
      _month1Count = month1Expenses.length;
      _month2Count = month2Expenses.length;
      _categoryTotals = categoryTotals;
      _isLoading = false;
    });
  }

  Future<void> _selectMonth(int monthNumber) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: monthNumber == 1 ? _month1 : _month2,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (picked != null) {
      setState(() {
        if (monthNumber == 1) {
          _month1 = DateTime(picked.year, picked.month, 1);
        } else {
          _month2 = DateTime(picked.year, picked.month, 1);
        }
      });
      await _loadData();
    }
  }

  String _getMonthName(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final difference = _month1Total - _month2Total;
    final percentage = _month2Total != 0
        ? ((difference / _month2Total) * 100).abs()
        : 0.0;
    final isIncrease = difference > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month 1 Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Month 1',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () => _selectMonth(1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getMonthName(_month1),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            Formatters.formatCurrency(_month1Total),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_month1Count expense${_month1Count == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Comparison Indicator
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isIncrease
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isIncrease ? Colors.red : Colors.green,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isIncrease ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${percentage.toStringAsFixed(1)}% ${isIncrease ? 'increase' : 'decrease'}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isIncrease ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Month 2 Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Month 2',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () => _selectMonth(2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getMonthName(_month2),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            Formatters.formatCurrency(_month2Total),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_month2Count expense${_month2Count == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Summary Card
                  Card(
                    elevation: 2,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryRow(
                            'Difference',
                            Formatters.formatCurrency(difference.abs()),
                            difference.isNegative ? '-' : '+',
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            'Higher Spending',
                            isIncrease ? _getMonthName(_month1) : _getMonthName(_month2),
                            '',
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            'Percentage Change',
                            '${percentage.toStringAsFixed(1)}%',
                            isIncrease ? '+' : '-',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pie Chart Section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Expense Distribution by Category',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_categoryTotals.isEmpty)
                            const Center(
                              child: Text(
                                'No expenses to display',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          else
                            Column(
                              children: [
                                SizedBox(
                                  height: 200,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 60,
                                      sections: _getPieChartSections(),
                                      pieTouchData: PieTouchData(
                                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                          setState(() {
                                            if (!event.isInterestedForInteractions ||
                                                pieTouchResponse == null ||
                                                pieTouchResponse.touchedSection == null) {
                                              _selectedCategoryIndex = -1;
                                              return;
                                            }
                                              _selectedCategoryIndex =
                                                  pieTouchResponse.touchedSection!.touchedSectionIndex;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildLegend(),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<PieChartSectionData> _getPieChartSections() {
    final total = _categoryTotals.values.fold<double>(0.0, (sum, value) => sum + value);
    final categories = _categoryTotals.keys.toList();
    
    return List.generate(categories.length, (index) {
      final category = categories[index];
      final amount = _categoryTotals[category]!;
      final percentage = (amount / total) * 100;
      final color = AppConstants.categoryColors[category] ?? Colors.grey;
      final isTouched = index == _selectedCategoryIndex;
      
      final radius = isTouched ? 60.0 : 50.0;
      
      return PieChartSectionData(
        color: color,
        value: amount,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: isTouched ? 16 : 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    });
  }

  Widget _buildLegend() {
    final total = _categoryTotals.values.fold<double>(0.0, (sum, value) => sum + value);
    final categories = _categoryTotals.keys.toList();
    
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: categories.map((category) {
        final amount = _categoryTotals[category]!;
        final percentage = (amount / total) * 100;
        final color = AppConstants.categoryColors[category] ?? Colors.grey;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$category: ${Formatters.formatCurrency(amount)} (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryRow(String label, String value, String prefix) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          prefix + value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
