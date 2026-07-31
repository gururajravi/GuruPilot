import 'package:flutter/material.dart';

import '../models/expense.dart';

class FinancialHealthCard extends StatelessWidget {
  final List<Expense> expenses;

  const FinancialHealthCard({super.key, required this.expenses});

  double _calculateScore() {
    if (expenses.isEmpty) return 100;

    final total = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final now = DateTime.now();

    final currentMonthExpenses = expenses.where((expense) {
      return expense.date.year == now.year && expense.date.month == now.month;
    }).toList();

    final currentMonthTotal = currentMonthExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final categoryCount = expenses
        .map((expense) => expense.category)
        .toSet()
        .length;

    double score = 100;

    if (currentMonthTotal > 50000) {
      score -= 35;
    } else if (currentMonthTotal > 30000) {
      score -= 25;
    } else if (currentMonthTotal > 15000) {
      score -= 15;
    }

    if (total > 100000) {
      score -= 15;
    }

    if (categoryCount <= 1) {
      score -= 10;
    }

    return score.clamp(0, 100);
  }

  String _getStatus(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Needs Attention';
    return 'High Spending Risk';
  }

  String _getMessage(double score) {
    if (score >= 80) {
      return 'Your spending pattern looks healthy and controlled.';
    }

    if (score >= 60) {
      return 'Your spending is generally stable, with room to improve.';
    }

    if (score >= 40) {
      return 'Review your largest categories and reduce avoidable expenses.';
    }

    return 'Your spending level is high. Consider setting a monthly budget.';
  }

  @override
  Widget build(BuildContext context) {
    final score = _calculateScore();
    final status = _getStatus(score);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 9,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  Text(
                    score.toStringAsFixed(0),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Health Score',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    status,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getMessage(score),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
