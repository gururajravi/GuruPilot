import 'package:flutter/material.dart';

import '../models/import_history.dart';
import '../services/import_history_service.dart';

class ImportHistoryScreen extends StatefulWidget {
  const ImportHistoryScreen({super.key});

  @override
  State<ImportHistoryScreen> createState() => _ImportHistoryScreenState();
}

class _ImportHistoryScreenState extends State<ImportHistoryScreen> {
  List<ImportHistory> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      history = ImportHistoryService.getAll();
    });
  }

  Future<void> _deleteHistory(ImportHistory item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete import history?'),
          content: const Text(
            'This deletes only the history record. '
            'Imported expenses and reviewed transactions '
            'will not be removed.',
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

    await ImportHistoryService.delete(item.id);

    if (!mounted) {
      return;
    }

    _loadHistory();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Import history deleted.')));
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} • '
        '$hour:$minute';
  }

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  int get _totalImports {
    return history.length;
  }

  int get _totalExpensesImported {
    return history.fold<int>(0, (sum, item) => sum + item.importedExpenses);
  }

  int get _totalReviewed {
    return history.fold<int>(0, (sum, item) => sum + item.reviewedTransactions);
  }

  double get _totalImportedAmount {
    return history.fold<double>(0, (sum, item) => sum + item.importedAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Import History'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: history.isEmpty
          ? const _EmptyHistoryState()
          : RefreshIndicator(
              onRefresh: () async {
                _loadHistory();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  _HistorySummaryCard(
                    totalImports: _totalImports,
                    totalExpensesImported: _totalExpensesImported,
                    totalReviewed: _totalReviewed,
                    totalImportedAmount: _totalImportedAmount,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Import Sessions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...history.map((item) {
                    return _ImportHistoryCard(
                      item: item,
                      formattedDateTime: _formatDateTime(item.importedAt),
                      formattedAmount: _formatAmount(item.importedAmount),
                      onDelete: () {
                        _deleteHistory(item);
                      },
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _HistorySummaryCard extends StatelessWidget {
  final int totalImports;
  final int totalExpensesImported;
  final int totalReviewed;
  final double totalImportedAmount;

  const _HistorySummaryCard({
    required this.totalImports,
    required this.totalExpensesImported,
    required this.totalReviewed,
    required this.totalImportedAmount,
  });

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
          const Text(
            'Import Overview',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${totalImportedAmount.toStringAsFixed(2)} imported',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 24,
            runSpacing: 14,
            children: [
              _SummaryMetric(label: 'Sessions', value: totalImports),
              _SummaryMetric(label: 'Expenses', value: totalExpensesImported),
              _SummaryMetric(label: 'Reviewed', value: totalReviewed),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final int value;

  const _SummaryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportHistoryCard extends StatelessWidget {
  final ImportHistory item;
  final String formattedDateTime;
  final String formattedAmount;
  final VoidCallback onDelete;

  const _ImportHistoryCard({
    required this.item,
    required this.formattedDateTime,
    required this.formattedAmount,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade100,
          child: const Icon(Icons.upload_file_outlined, color: Colors.indigo),
        ),
        title: Text(
          item.source,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(formattedDateTime),
        trailing: Text(
          formattedAmount,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          _HistoryValueRow(
            label: 'Transactions found',
            value: item.totalTransactions.toString(),
          ),
          _HistoryValueRow(
            label: 'Expenses imported',
            value: item.importedExpenses.toString(),
          ),
          _HistoryValueRow(
            label: 'Reviewed non-expenses',
            value: item.reviewedTransactions.toString(),
          ),
          _HistoryValueRow(
            label: 'Skipped',
            value: item.skippedTransactions.toString(),
          ),
          _HistoryValueRow(
            label: 'Merchant rules saved',
            value: item.merchantRulesSaved.toString(),
          ),
          _HistoryValueRow(label: 'Imported amount', value: formattedAmount),
          if (item.fileName != null && item.fileName!.trim().isNotEmpty)
            _HistoryValueRow(label: 'File', value: item.fileName!),
          if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.notes!,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete History'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _HistoryValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_outlined,
              size: 72,
              color: Colors.indigo.shade200,
            ),
            const SizedBox(height: 16),
            const Text(
              'No import history yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed PhonePe imports '
              'will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
