import 'package:flutter/material.dart';

import '../models/expense.dart';

class SpendingInsightsCard extends StatelessWidget {
  final List<Expense> expenses;

  const SpendingInsightsCard({super.key, required this.expenses});

  double get _total {
    return expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  Expense? get _highestExpense {
    if (expenses.isEmpty) return null;

    return expenses.reduce((current, next) {
      return current.amount >= next.amount ? current : next;
    });
  }

  Map<String, double> get _categoryTotals {
    final totals = <String, double>{};

    for (final expense in expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }

    return totals;
  }

  MapEntry<String, double>? get _topCategory {
    if (_categoryTotals.isEmpty) return null;

    return _categoryTotals.entries.reduce((current, next) {
      return current.value >= next.value ? current : next;
    });
  }

  double get _currentMonthTotal {
    final now = DateTime.now();

    return expenses
        .where(
          (expense) =>
              expense.date.year == now.year && expense.date.month == now.month,
        )
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  double get _previousMonthTotal {
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1);

    return expenses
        .where(
          (expense) =>
              expense.date.year == previousMonth.year &&
              expense.date.month == previousMonth.month,
        )
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  String _comparisonInsight() {
    final current = _currentMonthTotal;
    final previous = _previousMonthTotal;

    if (current == 0 && previous == 0) {
      return 'Add expenses from different months to compare spending.';
    }

    if (previous == 0) {
      return 'This month you have spent '
          '₹${current.toStringAsFixed(2)}.';
    }

    final differencePercentage = ((current - previous) / previous) * 100;

    if (differencePercentage > 0) {
      return 'Your spending increased by '
          '${differencePercentage.abs().toStringAsFixed(1)}% '
          'compared with last month.';
    }

    if (differencePercentage < 0) {
      return 'Your spending decreased by '
          '${differencePercentage.abs().toStringAsFixed(1)}% '
          'compared with last month.';
    }

    return 'Your spending is unchanged compared with last month.';
  }

  List<String> _buildInsights() {
    final insights = <String>[];
    final total = _total;
    final topCategory = _topCategory;
    final highestExpense = _highestExpense;

    if (topCategory != null && total > 0) {
      final percentage = topCategory.value / total * 100;

      insights.add(
        '${topCategory.key} accounts for '
        '${percentage.toStringAsFixed(1)}% of your total spending.',
      );
    }

    if (highestExpense != null) {
      insights.add(
        'Your biggest expense is ${highestExpense.title} '
        'at ₹${highestExpense.amount.toStringAsFixed(2)}.',
      );
    }

    if (expenses.isNotEmpty) {
      final average = total / expenses.length;

      insights.add(
        'Your average expense is '
        '₹${average.toStringAsFixed(2)} per transaction.',
      );
    }

    insights.add(_comparisonInsight());

    return insights;
  }

  @override
  Widget build(BuildContext context) {
    final insights = _buildInsights();

    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade50, Colors.white],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.auto_awesome, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GuruPilot Insights',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Smart analysis of your expenses',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...insights.map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 20,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
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
}
