import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/analytics_service.dart';
import '../widgets/financial_health_card.dart';
import '../widgets/monthly_trend_card.dart';
import '../widgets/spending_insights_card.dart';

class AnalyticsScreen extends StatefulWidget {
  final List<Expense> expenses;

  const AnalyticsScreen({super.key, required this.expenses});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
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

  String _selectedMonth = 'All';

  List<String> get _months {
    final months = widget.expenses
        .map((expense) => _monthKey(expense.date))
        .toSet()
        .toList();

    months.sort((first, second) => second.compareTo(first));

    return ['All', ...months];
  }

  List<Expense> get _filteredExpenses {
    if (_selectedMonth == 'All') {
      return [...widget.expenses];
    }

    return widget.expenses
        .where((expense) => _monthKey(expense.date) == _selectedMonth)
        .toList();
  }

  Map<String, double> get _monthlyTotals {
    final totals = <String, double>{};

    for (final expense in widget.expenses) {
      final key = _monthKey(expense.date);

      totals[key] = (totals[key] ?? 0) + expense.amount;
    }

    final sortedEntries = totals.entries.toList()
      ..sort((first, second) => first.key.compareTo(second.key));

    return {for (final entry in sortedEntries) entry.key: entry.value};
  }

  String _monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  String _monthLabel(String monthKey) {
    if (monthKey == 'All') {
      return 'All Months';
    }

    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${monthNames[month - 1]} $year';
  }

  String _shortMonthLabel(String monthKey) {
    final parts = monthKey.split('-');
    final year = parts[0].substring(2);
    final month = int.parse(parts[1]);

    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${monthNames[month - 1]} $year';
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = _filteredExpenses;
    final monthlyTotals = _monthlyTotals;

    if (widget.expenses.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Analytics'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: const _EmptyAnalytics(),
      );
    }

    final total = AnalyticsService.totalExpense(filteredExpenses);
    final average = AnalyticsService.averageExpense(filteredExpenses);
    final highest = AnalyticsService.highestExpense(filteredExpenses);
    final mostUsedCategory = AnalyticsService.mostUsedCategory(
      filteredExpenses,
    );
    final categoryTotals = AnalyticsService.categoryTotals(filteredExpenses);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _months.contains(_selectedMonth)
                  ? _selectedMonth
                  : 'All',
              decoration: InputDecoration(
                labelText: 'Month',
                prefixIcon: const Icon(Icons.calendar_view_month),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: _months.map((month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(_monthLabel(month)),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedMonth = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _TotalCard(total: total, periodLabel: _monthLabel(_selectedMonth)),
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
                    value: filteredExpenses.length.toString(),
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
              'Overall Monthly Expenses',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'All saved months are shown even when a month filter is selected.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            _MonthlyBarChartCard(
              monthlyTotals: monthlyTotals,
              selectedMonth: _selectedMonth,
              shortMonthLabel: _shortMonthLabel,
            ),
            const SizedBox(height: 24),
            Text(
              _selectedMonth == 'All'
                  ? 'Spending by Category'
                  : 'Spending by Category • ${_monthLabel(_selectedMonth)}',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (filteredExpenses.isEmpty)
              const _NoMatchingAnalytics()
            else ...[
              _CategoryChartCard(categoryTotals: categoryTotals, total: total),
              const SizedBox(height: 24),
              const Text(
                'Monthly Trend',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              MonthlyTrendCard(expenses: filteredExpenses),
              const SizedBox(height: 24),
              const Text(
                'Smart Insights',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SpendingInsightsCard(expenses: filteredExpenses),
              const SizedBox(height: 24),
              FinancialHealthCard(expenses: filteredExpenses),
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
          ],
        ),
      ),
    );
  }
}

class _MonthlyBarChartCard extends StatelessWidget {
  final Map<String, double> monthlyTotals;
  final String selectedMonth;
  final String Function(String) shortMonthLabel;

  const _MonthlyBarChartCard({
    required this.monthlyTotals,
    required this.selectedMonth,
    required this.shortMonthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final entries = monthlyTotals.entries.toList();

    final highestValue = entries.fold<double>(
      0,
      (current, entry) => math.max(current, entry.value),
    );

    final maxY = highestValue == 0 ? 1000.0 : highestValue * 1.2;

    final interval = maxY / 4;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          children: [
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final entry = entries[group.x.toInt()];

                        return BarTooltipItem(
                          '${_fullMonthLabel(entry.key)}\n'
                          '₹${entry.value.toStringAsFixed(2)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              _compactRupees(value),
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();

                          if (index < 0 || index >= entries.length) {
                            return const SizedBox.shrink();
                          }

                          final monthKey = entries[index].key;

                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: Text(
                              shortMonthLabel(monthKey),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: monthKey == selectedMonth
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: monthKey == selectedMonth
                                    ? Colors.indigo
                                    : Colors.grey.shade700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(entries.length, (index) {
                    final entry = entries[index];

                    final isSelected = entry.key == selectedMonth;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          width: entries.length > 8 ? 16 : 24,
                          color: isSelected ? Colors.orange : Colors.indigo,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap or hover over a bar to see the exact monthly amount.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  static String _compactRupees(double value) {
    if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(1)}L';
    }

    if (value >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(0)}K';
    }

    return '₹${value.toStringAsFixed(0)}';
  }

  static String _fullMonthLabel(String monthKey) {
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${names[month - 1]} $year';
  }
}

class _TotalCard extends StatelessWidget {
  final double total;
  final String periodLabel;

  const _TotalCard({required this.total, required this.periodLabel});

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
          const SizedBox(height: 6),
          Text(periodLabel, style: const TextStyle(color: Colors.white70)),
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
                          _AnalyticsScreenState._chartColors[index %
                              _AnalyticsScreenState._chartColors.length],
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
                            _AnalyticsScreenState._chartColors[index %
                                _AnalyticsScreenState._chartColors.length],
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
      case 'guru office food':
        return '🍱';
      case 'grocery':
        return '🛍️';
      case 'bike':
        return '🏍️';
      case 'car':
        return '🚗';
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
      case 'guru personal':
      case 'ananya personal':
        return '👤';
      default:
        return '📦';
    }
  }
}

class _NoMatchingAnalytics extends StatelessWidget {
  const _NoMatchingAnalytics();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.filter_alt_off_outlined,
                size: 56,
                color: Colors.indigo.shade200,
              ),
              const SizedBox(height: 12),
              const Text(
                'No expenses found for this month.',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
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
