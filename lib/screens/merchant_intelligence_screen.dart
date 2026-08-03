import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/merchant_rule.dart';
import '../services/expense_service.dart';
import '../services/merchant_rule_service.dart';

class MerchantIntelligenceScreen extends StatefulWidget {
  const MerchantIntelligenceScreen({super.key});

  @override
  State<MerchantIntelligenceScreen> createState() =>
      _MerchantIntelligenceScreenState();
}

class _MerchantIntelligenceScreenState
    extends State<MerchantIntelligenceScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<MerchantRule> rules = [];
  List<Expense> expenses = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      rules = MerchantRuleService.getRules();
      expenses = ExpenseService.getExpenses();
    });
  }

  List<MerchantRule> get _filteredRules {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return rules;
    }

    return rules.where((rule) {
      final searchableText = [
        rule.merchantName,
        rule.category,
        rule.person,
        rule.paymentMethod,
      ].join(' ').toLowerCase();

      return searchableText.contains(query);
    }).toList();
  }

  List<Expense> _expensesForMerchant(String merchantName) {
    final normalizedMerchant = merchantName.trim().toLowerCase();

    return expenses.where((expense) {
      final expenseMerchant = (expense.merchant ?? expense.title)
          .trim()
          .toLowerCase();

      return expenseMerchant == normalizedMerchant;
    }).toList()..sort((first, second) => second.date.compareTo(first.date));
  }

  double _totalSpent(List<Expense> merchantExpenses) {
    return merchantExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
  }

  double _averageSpent(List<Expense> merchantExpenses) {
    if (merchantExpenses.isEmpty) {
      return 0;
    }

    return _totalSpent(merchantExpenses) / merchantExpenses.length;
  }

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  Future<void> _deleteRule(MerchantRule rule) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete merchant rule?'),
          content: Text(
            'Future transactions from '
            '${rule.merchantName} will no longer '
            'be categorized automatically.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await MerchantRuleService.deleteRule(rule);

    if (!mounted) {
      return;
    }

    _loadData();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Merchant rule deleted.')));
  }

  void _openMerchantDetails(MerchantRule rule) {
    final merchantExpenses = _expensesForMerchant(rule.merchantName);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MerchantDetailsScreen(rule: rule, expenses: merchantExpenses),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleRules = _filteredRules;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Merchant Intelligence'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: rules.isEmpty
          ? const _EmptyMerchantState()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search merchant or category',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();

                                setState(() {
                                  searchQuery = '';
                                });
                              },
                              icon: const Icon(Icons.close),
                            ),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Saved Merchant Rules',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${visibleRules.length}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: visibleRules.isEmpty
                      ? const Center(
                          child: Text('No merchants match your search.'),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            _loadData();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                            itemCount: visibleRules.length,
                            itemBuilder: (context, index) {
                              final rule = visibleRules[index];

                              final merchantExpenses = _expensesForMerchant(
                                rule.merchantName,
                              );

                              return _MerchantRuleCard(
                                rule: rule,
                                transactionCount: merchantExpenses.length,
                                totalSpent: _formatAmount(
                                  _totalSpent(merchantExpenses),
                                ),
                                averageSpent: _formatAmount(
                                  _averageSpent(merchantExpenses),
                                ),
                                onTap: () {
                                  _openMerchantDetails(rule);
                                },
                                onDelete: () {
                                  _deleteRule(rule);
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class MerchantDetailsScreen extends StatelessWidget {
  final MerchantRule rule;
  final List<Expense> expenses;

  const MerchantDetailsScreen({
    super.key,
    required this.rule,
    required this.expenses,
  });

  double get totalSpent {
    return expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  double get averageSpent {
    if (expenses.isEmpty) {
      return 0;
    }

    return totalSpent / expenses.length;
  }

  double get highestSpent {
    if (expenses.isEmpty) {
      return 0;
    }

    return expenses
        .map((expense) => expense.amount)
        .reduce((first, second) => first > second ? first : second);
  }

  DateTime? get firstPurchase {
    if (expenses.isEmpty) {
      return null;
    }

    final sorted = [...expenses]
      ..sort((first, second) => first.date.compareTo(second.date));

    return sorted.first.date;
  }

  DateTime? get lastPurchase {
    if (expenses.isEmpty) {
      return null;
    }

    final sorted = [...expenses]
      ..sort((first, second) => second.date.compareTo(first.date));

    return sorted.first.date;
  }

  Map<DateTime, double> get monthlySpend {
    final result = <DateTime, double>{};

    for (final expense in expenses) {
      final monthKey = DateTime(expense.date.year, expense.date.month);

      result[monthKey] = (result[monthKey] ?? 0) + expense.amount;
    }

    final entries = result.entries.toList()
      ..sort((first, second) => first.key.compareTo(second.key));

    final recentEntries = entries.length <= 6
        ? entries
        : entries.sublist(entries.length - 6);

    return Map<DateTime, double>.fromEntries(recentEntries);
  }

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(rule.merchantName),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _MerchantProfileCard(rule: rule),
          const SizedBox(height: 16),
          _MerchantStatsCard(
            transactionCount: expenses.length,
            totalSpent: _formatAmount(totalSpent),
            averageSpent: _formatAmount(averageSpent),
            highestSpent: _formatAmount(highestSpent),
          ),
          const SizedBox(height: 16),
          _MerchantTimelineCard(
            firstPurchase: firstPurchase,
            lastPurchase: lastPurchase,
          ),
          const SizedBox(height: 16),
          _MerchantTrendCard(monthlySpend: monthlySpend),
          const SizedBox(height: 20),
          const Text(
            'Transactions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (expenses.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No imported expenses found for this merchant.'),
              ),
            )
          else
            ...expenses.map((expense) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.receipt_long_outlined),
                  ),
                  title: Text(
                    expense.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${_formatDate(expense.date)} • '
                    '${expense.category} • '
                    '${expense.person}',
                  ),
                  trailing: Text(
                    _formatAmount(expense.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MerchantTimelineCard extends StatelessWidget {
  final DateTime? firstPurchase;
  final DateTime? lastPurchase;

  const _MerchantTimelineCard({
    required this.firstPurchase,
    required this.lastPurchase,
  });

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: _TimelineValue(
                label: 'First Purchase',
                value: firstPurchase == null
                    ? '—'
                    : _formatDate(firstPurchase!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _TimelineValue(
                label: 'Last Purchase',
                value: lastPurchase == null ? '—' : _formatDate(lastPurchase!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineValue extends StatelessWidget {
  final String label;
  final String value;

  const _TimelineValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _MerchantTrendCard extends StatelessWidget {
  final Map<DateTime, double> monthlySpend;

  const _MerchantTrendCard({required this.monthlySpend});

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
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

    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final entries = monthlySpend.entries.toList();

    final maxAmount = entries.isEmpty
        ? 0.0
        : entries
              .map((entry) => entry.value)
              .reduce((first, second) => first > second ? first : second);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last 6 Months',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            if (entries.isEmpty)
              const Text('No monthly trend available.')
            else
              ...entries.map((entry) {
                final progress = maxAmount == 0 ? 0.0 : entry.value / maxAmount;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(_monthLabel(entry.key))),
                          Text(
                            _formatAmount(entry.value),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _MerchantRuleCard extends StatelessWidget {
  final MerchantRule rule;
  final int transactionCount;
  final String totalSpent;
  final String averageSpent;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MerchantRuleCard({
    required this.rule,
    required this.transactionCount,
    required this.totalSpent,
    required this.averageSpent,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.indigo.shade100,
                child: const Icon(
                  Icons.storefront_outlined,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.merchantName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _InfoChip(
                          label: rule.category,
                          icon: Icons.category_outlined,
                        ),
                        _InfoChip(
                          label: rule.person,
                          icon: Icons.person_outline,
                        ),
                        _InfoChip(
                          label: rule.paymentMethod,
                          icon: Icons.payments_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$transactionCount transactions • '
                      '$totalSpent total • '
                      '$averageSpent average',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete rule'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MerchantProfileCard extends StatelessWidget {
  final MerchantRule rule;

  const _MerchantProfileCard({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.storefront_outlined, color: Colors.white, size: 34),
          const SizedBox(height: 12),
          Text(
            rule.merchantName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _ProfileValue(label: 'Category', value: rule.category),
          _ProfileValue(label: 'Expense For', value: rule.person),
          _ProfileValue(label: 'Payment', value: rule.paymentMethod),
        ],
      ),
    );
  }
}

class _ProfileValue extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantStatsCard extends StatelessWidget {
  final int transactionCount;
  final String totalSpent;
  final String averageSpent;
  final String highestSpent;

  const _MerchantStatsCard({
    required this.transactionCount,
    required this.totalSpent,
    required this.averageSpent,
    required this.highestSpent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _StatValue(
              label: 'Transactions',
              value: transactionCount.toString(),
            ),
            _StatValue(label: 'Total Spend', value: totalSpent),
            _StatValue(label: 'Average', value: averageSpent),
            _StatValue(label: 'Highest', value: highestSpent),
          ],
        ),
      ),
    );
  }
}

class _StatValue extends StatelessWidget {
  final String label;
  final String value;

  const _StatValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _EmptyMerchantState extends StatelessWidget {
  const _EmptyMerchantState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 72,
              color: Colors.indigo.shade200,
            ),
            const SizedBox(height: 16),
            const Text(
              'No merchant rules yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enable “Remember this merchant mapping” '
              'while importing PhonePe transactions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
