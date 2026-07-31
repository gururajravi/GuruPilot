import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/analytics_service.dart';

class AnalyticsScreen extends StatelessWidget {
  final List<Expense> expenses;

  const AnalyticsScreen({super.key, required this.expenses});

  static const List<Color> _chartColors = [
    Colors.indigo,
    Colors.orange,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.blue,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    final total = AnalyticsService.totalExpense(expenses);
    final average = AnalyticsService.averageExpense(expenses);
    final highest = AnalyticsService.highestExpense(expenses);
    final mostUsedCategory = AnalyticsService.mostUsedCategory(expenses);
    final categoryTotals = AnalyticsService.categoryTotals(expenses);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: expenses.isEmpty
          ? const _EmptyAnalytics()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TotalCard(total: total),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatisticCard(
                          title: 'Average',
                          value: '₹${average.toStringAsFixed(2)}',
                          icon: Icons.calculate_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatisticCard(
                          title: 'Transactions',
                          value: expenses.length.toString(),
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatisticCard(
                          title: 'Highest',
                          value: highest == null
                              ? '₹0.00'
                              : '₹${highest.amount.toStringAsFixed(2)}',
                          icon: Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatisticCard(
                          title: 'Top Category',
                          value: mostUsedCategory,
                          icon: Icons.category_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Spending by Category',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _CategoryChartCard(
                    categoryTotals: categoryTotals,
                    total: total,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Highest Expense',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (highest != null) _HighestExpenseCard(expense: highest),
                  const SizedBox(height: 24),
                  const Text(
                    'Category Breakdown',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...categoryTotals.entries.map((entry) {
                    final percentage = total == 0 ? 0.0 : entry.value / total;

                    return _CategoryProgressCard(
                      category: entry.key,
                      amount: entry.value,
                      percentage: percentage,
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double total;

  const _TotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.white70),
              SizedBox(width: 8),
              Text(
                'Total Spending',
                style: TextStyle(color: Colors.white70, fontSize: 17),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatisticCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.indigo, size: 30),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

class _CategoryChartCard extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final double total;

  const _CategoryChartCard({required this.categoryTotals, required this.total});

  @override
  Widget build(BuildContext context) {
    final entries = categoryTotals.entries.toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              height: 260,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 55,
                  sectionsSpace: 3,
                  sections: List.generate(entries.length, (index) {
                    final entry = entries[index];
                    final percentage = total == 0
                        ? 0.0
                        : entry.value / total * 100;

                    return PieChartSectionData(
                      value: entry.value,
                      color:
                          AnalyticsScreen._chartColors[index %
                              AnalyticsScreen._chartColors.length],
                      radius: 78,
                      title: '${percentage.toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 14,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(entries.length, (index) {
                final entry = entries[index];

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color:
                            AnalyticsScreen._chartColors[index %
                                AnalyticsScreen._chartColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${entry.key} ₹${entry.value.toStringAsFixed(0)}'),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighestExpenseCard extends StatelessWidget {
  final Expense expense;

  const _HighestExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.indigo.shade100,
          child: const Icon(Icons.trending_up, color: Colors.indigo),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${expense.category} • '
          '${expense.date.day}/${expense.date.month}/${expense.date.year}',
        ),
        trailing: Text(
          '₹${expense.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.green,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _CategoryProgressCard extends StatelessWidget {
  final String category;
  final double amount;
  final double percentage;

  const _CategoryProgressCard({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(
                    _categoryEmoji(category),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return '🍔';
      case 'fuel':
        return '⛽';
      case 'shopping':
        return '🛒';
      case 'bills':
        return '💡';
      case 'travel':
        return '✈️';
      case 'medical':
        return '💊';
      case 'entertainment':
        return '🎬';
      default:
        return '📦';
    }
  }
}

class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: Colors.indigo.shade200,
            ),
            const SizedBox(height: 18),
            const Text(
              'No analytics available',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some expenses to see charts and spending insights.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
