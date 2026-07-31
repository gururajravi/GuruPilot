import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/expense.dart';

class MonthlyTrendCard extends StatelessWidget {
  final List<Expense> expenses;

  const MonthlyTrendCard({super.key, required this.expenses});

  Map<DateTime, double> _monthlyTotals() {
    final totals = <DateTime, double>{};

    for (final expense in expenses) {
      final month = DateTime(expense.date.year, expense.date.month);

      totals[month] = (totals[month] ?? 0) + expense.amount;
    }

    final sortedEntries = totals.entries.toList()
      ..sort((first, second) => first.key.compareTo(second.key));

    // Display only the latest six months that contain expenses.
    final visibleEntries = sortedEntries.length > 6
        ? sortedEntries.sublist(sortedEntries.length - 6)
        : sortedEntries;

    return Map<DateTime, double>.fromEntries(visibleEntries);
  }

  String _monthLabel(DateTime date) {
    const months = [
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

    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final monthlyTotals = _monthlyTotals();
    final entries = monthlyTotals.entries.toList();

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = List.generate(
      entries.length,
      (index) => FlSpot(index.toDouble(), entries[index].value),
    );

    final highestAmount = entries.map((entry) => entry.value).reduce(max);

    final maximumY = highestAmount == 0 ? 100.0 : highestAmount * 1.25;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.show_chart, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Monthly Spending Trend',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Spending across your latest months',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: max(0, entries.length - 1).toDouble(),
                  minY: 0,
                  maxY: maximumY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maximumY / 4,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                      bottom: BorderSide(color: Colors.grey.shade300),
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
                        interval: maximumY / 4,
                        getTitlesWidget: (value, metadata) {
                          return Text(
                            '₹${value.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 1,
                        getTitlesWidget: (value, metadata) {
                          final index = value.toInt();

                          if (index < 0 || index >= entries.length) {
                            return const SizedBox.shrink();
                          }

                          final date = entries[index].key;

                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              _monthLabel(date),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          final entry = entries[index];

                          return LineTooltipItem(
                            '${_monthLabel(entry.key)} '
                            '${entry.key.year}\n'
                            '₹${entry.value.toStringAsFixed(2)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: entries.length > 2,
                      barWidth: 4,
                      color: Colors.indigo,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.indigo.withValues(alpha: 0.12),
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
