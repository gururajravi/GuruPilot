import 'package:flutter/material.dart';

import '../models/expense.dart';

class DashboardScreen extends StatefulWidget {
  final List<Expense> expenses;

  const DashboardScreen({super.key, required this.expenses});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime selectedMonth;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    selectedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final monthExpenses = widget.expenses.where((expense) {
      return expense.date.year == selectedMonth.year &&
          expense.date.month == selectedMonth.month;
    }).toList()..sort((first, second) => second.date.compareTo(first.date));

    final previousMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);

    final previousMonthExpenses = widget.expenses.where((expense) {
      return expense.date.year == previousMonth.year &&
          expense.date.month == previousMonth.month;
    }).toList();

    final monthTotal = monthExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final previousMonthTotal = previousMonthExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final comparisonPercentage = previousMonthTotal == 0
        ? null
        : ((monthTotal - previousMonthTotal) / previousMonthTotal) * 100;

    final categoryTotals = <String, double>{};

    for (final expense in monthExpenses) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final categoryEntries = categoryTotals.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));

    final topCategory = categoryEntries.isEmpty ? null : categoryEntries.first;

    final now = DateTime.now();

    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;

    final daysForAverage = isCurrentMonth
        ? now.day
        : DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

    final dailyAverage = daysForAverage == 0
        ? 0.0
        : monthTotal / daysForAverage;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text(
          'GuruFin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MonthNavigator(
              selectedMonth: selectedMonth,
              onPrevious: _previousMonth,
              onNext: _nextMonth,
              canGoNext: _canGoNext,
            ),

            const SizedBox(height: 16),

            _WalletSummaryCard(
              month: _monthLabel(selectedMonth),
              total: monthTotal,
              transactionCount: monthExpenses.length,
              dailyAverage: dailyAverage,
              comparisonPercentage: comparisonPercentage,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Transactions',
                    value: monthExpenses.length.toString(),
                    subtitle: 'This month',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.category_outlined,
                    title: 'Categories',
                    value: categoryTotals.length.toString(),
                    subtitle: 'Used this month',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.calendar_month_outlined,
                    title: 'Daily Average',
                    value: _formatAmount(dailyAverage),
                    subtitle: 'Average spend',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.trending_up_outlined,
                    title: 'Top Category',
                    value: topCategory?.key ?? '—',
                    subtitle: topCategory == null
                        ? 'No spending'
                        : _formatAmount(topCategory.value),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            _SectionHeader(
              title: 'Spending Breakdown',
              trailing: _formatAmount(monthTotal),
            ),

            const SizedBox(height: 12),

            if (categoryEntries.isEmpty)
              const _EmptyCard(
                icon: Icons.pie_chart_outline,
                title: 'No spending this month',
                subtitle: 'Your category spending will appear here.',
              )
            else
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: categoryEntries
                        .take(7)
                        .map(
                          (entry) => _CategoryRow(
                            category: entry.key,
                            amount: entry.value,
                            total: monthTotal,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),

            const SizedBox(height: 28),

            _SectionHeader(
              title: 'Recent Expenses',
              trailing: '${monthExpenses.length} transactions',
            ),

            const SizedBox(height: 12),

            if (monthExpenses.isEmpty)
              const _EmptyCard(
                icon: Icons.receipt_long_outlined,
                title: 'No expenses found',
                subtitle: 'There are no expenses for this month yet.',
              )
            else
              ...monthExpenses
                  .take(8)
                  .map((expense) => _RecentExpenseCard(expense: expense)),

            const SizedBox(height: 28),

            _AllTimeOverview(expenses: widget.expenses),
          ],
        ),
      ),
    );
  }

  bool get _canGoNext {
    final now = DateTime.now();

    return selectedMonth.year < now.year ||
        (selectedMonth.year == now.year && selectedMonth.month < now.month);
  }

  void _previousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    if (!_canGoNext) {
      return;
    }

    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    });
  }

  static String _monthLabel(DateTime date) {
    const months = [
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

    return '${months[date.month - 1]} ${date.year}';
  }

  static String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }
}

class _MonthNavigator extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoNext;

  const _MonthNavigator({
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
    required this.canGoNext,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              tooltip: 'Previous month',
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'Viewing',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _monthLabel(selectedMonth),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: canGoNext ? onNext : null,
              tooltip: 'Next month',
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  static String _monthLabel(DateTime date) {
    const months = [
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

    return '${months[date.month - 1]} ${date.year}';
  }
}

class _WalletSummaryCard extends StatelessWidget {
  final String month;
  final double total;
  final int transactionCount;
  final double dailyAverage;
  final double? comparisonPercentage;

  const _WalletSummaryCard({
    required this.month,
    required this.total,
    required this.transactionCount,
    required this.dailyAverage,
    required this.comparisonPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final spendingIncreased =
        comparisonPercentage != null && comparisonPercentage! > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white70,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'My Wallet Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Text(month, style: const TextStyle(color: Colors.white70)),

          const SizedBox(height: 22),

          const Text(
            'Spent this month',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),

          const SizedBox(height: 5),

          Text(
            '₹${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          if (comparisonPercentage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    spendingIncreased
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${comparisonPercentage!.abs().toStringAsFixed(1)}% '
                    '${spendingIncreased ? 'higher' : 'lower'} '
                    'than previous month',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _WalletMetric(
                    label: 'Transactions',
                    value: transactionCount.toString(),
                  ),
                ),
                Container(width: 1, height: 42, color: Colors.white24),
                Expanded(
                  child: _WalletMetric(
                    label: 'Daily Average',
                    value: '₹${dailyAverage.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletMetric extends StatelessWidget {
  final String label;
  final String value;

  const _WalletMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _QuickStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.indigo.withValues(alpha: 0.10),
              child: Icon(icon, color: Colors.indigo, size: 21),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
            ),
            const SizedBox(height: 3),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String trailing;

  const _SectionHeader({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          trailing,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final double amount;
  final double total;

  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total <= 0 ? 0.0 : (amount / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.indigo.withValues(alpha: 0.10),
                child: Text(
                  _categoryEmoji(category),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 42,
                child: Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
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
      case 'fuel':
        return '⛽';
      case 'car':
        return '🚗';
      case 'bike':
        return '🏍️';
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
      case 'personal':
      case 'guru personal':
      case 'ananya personal':
        return '👤';
      default:
        return '📦';
    }
  }
}

class _RecentExpenseCard extends StatelessWidget {
  final Expense expense;

  const _RecentExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.withValues(alpha: 0.10),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.indigo,
          ),
        ),
        title: Text(
          expense.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${expense.category} • '
          '${expense.date.day}/${expense.date.month}/${expense.date.year}',
        ),
        trailing: Text(
          '₹${expense.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}

class _AllTimeOverview extends StatelessWidget {
  final List<Expense> expenses;

  const _AllTimeOverview({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final categories = expenses.map((e) => e.category).toSet().length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All-Time Overview',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 16),
            _OverviewRow(
              label: 'Total Expenses',
              value: '₹${total.toStringAsFixed(2)}',
            ),
            _OverviewRow(
              label: 'Transactions',
              value: expenses.length.toString(),
            ),
            _OverviewRow(label: 'Categories', value: categories.toString()),
          ],
        ),
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _OverviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 38, color: Colors.grey),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
