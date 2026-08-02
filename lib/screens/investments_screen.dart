import 'package:flutter/material.dart';

import '../models/investment.dart';
import '../services/investment_service.dart';
import 'add_investment_screen.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  List<Investment> investments = [];

  DateTime? _fromDate;
  DateTime _toDate = _dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadInvestments();
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _loadInvestments() {
    final loadedInvestments = InvestmentService.getInvestments();

    setState(() {
      investments = loadedInvestments;
    });
  }

  List<Investment> get _filteredInvestments {
    final fromDate = _fromDate == null ? null : _dateOnly(_fromDate!);

    final toDate = _dateOnly(_toDate);

    final filtered = investments.where((investment) {
      final investmentDate = _dateOnly(investment.date);

      final fromDateMatches =
          fromDate == null || !investmentDate.isBefore(fromDate);

      final toDateMatches = !investmentDate.isAfter(toDate);

      return fromDateMatches && toDateMatches;
    }).toList();

    filtered.sort((first, second) => second.date.compareTo(first.date));

    return filtered;
  }

  Future<void> _selectFromDate() async {
    final today = _dateOnly(DateTime.now());

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? _earliestInvestmentDate(),
      firstDate: DateTime(2000),
      lastDate: _toDate.isAfter(today) ? today : _toDate,
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      _fromDate = _dateOnly(pickedDate);

      if (_fromDate!.isAfter(_toDate)) {
        _toDate = _fromDate!;
      }
    });
  }

  Future<void> _selectToDate() async {
    final today = _dateOnly(DateTime.now());

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate ?? DateTime(2000),
      lastDate: today,
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      _toDate = _dateOnly(pickedDate);
    });
  }

  DateTime _earliestInvestmentDate() {
    if (investments.isEmpty) {
      return _dateOnly(DateTime.now());
    }

    final dates =
        investments.map((investment) => _dateOnly(investment.date)).toList()
          ..sort();

    final earliestDate = dates.first;
    final today = _dateOnly(DateTime.now());

    if (earliestDate.isAfter(today)) {
      return today;
    }

    return earliestDate;
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = _dateOnly(DateTime.now());
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _filterPeriodLabel() {
    final fromLabel = _fromDate == null ? 'Start' : _formatDate(_fromDate!);

    return '$fromLabel to ${_formatDate(_toDate)}';
  }

  Map<String, List<Investment>> _groupByType(List<Investment> source) {
    final grouped = <String, List<Investment>>{};

    for (final investment in source) {
      grouped.putIfAbsent(investment.type, () => <Investment>[]);

      grouped[investment.type]!.add(investment);
    }

    return grouped;
  }

  Future<void> _addInvestment() async {
    final investment = await Navigator.push<Investment>(
      context,
      MaterialPageRoute(builder: (_) => const AddInvestmentScreen()),
    );

    if (investment == null) return;

    try {
      await InvestmentService.addInvestment(investment);

      if (!mounted) return;

      _loadInvestments();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Investment added successfully.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to add investment: $error')),
      );
    }
  }

  Future<void> _editInvestment(Investment investment) async {
    final updatedInvestment = await Navigator.push<Investment>(
      context,
      MaterialPageRoute(
        builder: (_) => AddInvestmentScreen(investment: investment),
      ),
    );

    if (updatedInvestment == null) return;

    try {
      await InvestmentService.updateInvestment(investment, updatedInvestment);

      if (!mounted) return;

      _loadInvestments();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Investment updated successfully.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update investment: $error')),
      );
    }
  }

  Future<void> _deleteInvestment(Investment investment) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Investment'),
          content: Text('Delete "${investment.title}" permanently?'),
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
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await InvestmentService.deleteInvestment(investment);

      if (!mounted) return;

      _loadInvestments();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Investment deleted.')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete investment: $error')),
      );
    }
  }

  String _typeEmoji(String type) {
    switch (type) {
      case 'Mutual Fund':
        return '📈';

      case 'Chit Fund':
        return '🤝';

      case 'Stock':
        return '📊';

      case 'Gold':
        return '🪙';

      case 'Property':
        return '🏠';

      case 'LIC':
        return '🛡️';

      case 'Fixed Deposit':
        return '🏦';

      case 'EPF':
        return '💼';

      case 'PPF':
        return '💰';

      case 'NPS':
        return '📅';

      default:
        return '📦';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredInvestments = _filteredInvestments;

    final totalInvested = filteredInvestments.fold<double>(
      0,
      (sum, investment) => sum + investment.investedAmount,
    );

    final groupedInvestments = _groupByType(filteredInvestments);

    final chitFunds = groupedInvestments['Chit Fund'] ?? [];

    final chitFundTotal = chitFunds.fold<double>(
      0,
      (sum, investment) => sum + investment.investedAmount,
    );

    final filterIsActive =
        _fromDate != null || _toDate != _dateOnly(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Investments'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addInvestment,
        child: const Icon(Icons.add),
      ),
      body: investments.isEmpty
          ? _EmptyInvestments(onAddInvestment: _addInvestment)
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DateRangeFilterCard(
                    fromDate: _fromDate,
                    toDate: _toDate,
                    formatDate: _formatDate,
                    onSelectFromDate: _selectFromDate,
                    onSelectToDate: _selectToDate,
                    onClearFilters: _clearFilters,
                    filterIsActive: filterIsActive,
                  ),

                  const SizedBox(height: 16),

                  _InvestmentSummaryCard(
                    totalInvested: totalInvested,
                    investmentCount: filteredInvestments.length,
                    typeCount: groupedInvestments.length,
                    periodLabel: _filterPeriodLabel(),
                  ),

                  if (chitFunds.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _ChitFundSummaryCard(
                      total: chitFundTotal,
                      installmentCount: chitFunds.length,
                    ),
                  ],

                  const SizedBox(height: 24),

                  Text(
                    'Investment Categories • '
                    '${_filterPeriodLabel()}',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (filteredInvestments.isEmpty)
                    const _NoInvestmentsForFilter()
                  else ...[
                    ...groupedInvestments.entries.map((entry) {
                      final categoryTotal = entry.value.fold<double>(
                        0,
                        (sum, investment) => sum + investment.investedAmount,
                      );

                      return _InvestmentTypeCard(
                        type: entry.key,
                        emoji: _typeEmoji(entry.key),
                        total: categoryTotal,
                        count: entry.value.length,
                      );
                    }),

                    const SizedBox(height: 24),

                    Text(
                      'Investment History • '
                      '${_filterPeriodLabel()}',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    ...filteredInvestments.map((investment) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade100,
                            child: Text(_typeEmoji(investment.type)),
                          ),
                          title: Text(
                            investment.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${investment.type} • '
                            '${investment.owner}\n'
                            '${_formatDate(investment.date)}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${investment.investedAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editInvestment(investment);
                                  }

                                  if (value == 'delete') {
                                    _deleteInvestment(investment);
                                  }
                                },
                                itemBuilder: (_) {
                                  return const [
                                    PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined),
                                          SizedBox(width: 10),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ];
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            _editInvestment(investment);
                          },
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }
}

class _DateRangeFilterCard extends StatelessWidget {
  final DateTime? fromDate;
  final DateTime toDate;
  final String Function(DateTime) formatDate;
  final VoidCallback onSelectFromDate;
  final VoidCallback onSelectToDate;
  final VoidCallback onClearFilters;
  final bool filterIsActive;

  const _DateRangeFilterCard({
    required this.fromDate,
    required this.toDate,
    required this.formatDate,
    required this.onSelectFromDate,
    required this.onSelectToDate,
    required this.onClearFilters,
    required this.filterIsActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.date_range_outlined, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Investment Date Range',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _DateFilterButton(
                    label: 'From Date',
                    value: fromDate == null
                        ? 'Beginning'
                        : formatDate(fromDate!),
                    icon: Icons.first_page,
                    onPressed: onSelectFromDate,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _DateFilterButton(
                    label: 'To Date',
                    value: formatDate(toDate),
                    icon: Icons.today_outlined,
                    onPressed: onSelectToDate,
                  ),
                ),
              ],
            ),

            if (filterIsActive) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Reset to today'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateFilterButton extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onPressed;

  const _DateFilterButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvestmentSummaryCard extends StatelessWidget {
  final double totalInvested;
  final int investmentCount;
  final int typeCount;
  final String periodLabel;

  const _InvestmentSummaryCard({
    required this.totalInvested,
    required this.investmentCount,
    required this.typeCount,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white70,
              ),
              SizedBox(width: 8),
              Text(
                'Total Invested',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(periodLabel, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Text(
            '₹${totalInvested.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  label: 'Entries',
                  value: investmentCount.toString(),
                ),
              ),
              Expanded(
                child: _SummaryValue(
                  label: 'Categories',
                  value: typeCount.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChitFundSummaryCard extends StatelessWidget {
  final double total;
  final int installmentCount;

  const _ChitFundSummaryCard({
    required this.total,
    required this.installmentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.indigo.shade100,
              child: const Text('🤝', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chit Fund',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$installmentCount installment'
                    '${installmentCount == 1 ? '' : 's'}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            Text(
              '₹${total.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvestmentTypeCard extends StatelessWidget {
  final String type;
  final String emoji;
  final double total;
  final int count;

  const _InvestmentTypeCard({
    required this.type,
    required this.emoji,
    required this.total,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade100,
          child: Text(emoji),
        ),
        title: Text(type, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$count entr${count == 1 ? 'y' : 'ies'}'),
        trailing: Text(
          '₹${total.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _NoInvestmentsForFilter extends StatelessWidget {
  const _NoInvestmentsForFilter();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.filter_alt_off_outlined,
                size: 58,
                color: Colors.indigo.shade200,
              ),
              const SizedBox(height: 12),
              const Text(
                'No investments found for the selected date range.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyInvestments extends StatelessWidget {
  final VoidCallback onAddInvestment;

  const _EmptyInvestments({required this.onAddInvestment});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 82,
              color: Colors.indigo.shade200,
            ),
            const SizedBox(height: 18),
            const Text(
              'No investments added',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add chit funds, mutual funds, gold, '
              'property and other assets.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAddInvestment,
              icon: const Icon(Icons.add),
              label: const Text('Add Investment'),
            ),
          ],
        ),
      ),
    );
  }
}
