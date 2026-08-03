import 'package:flutter/material.dart';

import '../models/import_review_item.dart';
import '../models/import_transaction.dart';
import '../services/import_service.dart';
import 'import_review_screen.dart';
import 'smart_sync_screen.dart';

class ImportTransactionsScreen extends StatefulWidget {
  const ImportTransactionsScreen({super.key});

  @override
  State<ImportTransactionsScreen> createState() =>
      _ImportTransactionsScreenState();
}

class _ImportTransactionsScreenState extends State<ImportTransactionsScreen> {
  List<ImportTransaction> transactions = [];

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickFile() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final parsedTransactions = await ImportService.pickAndParsePhonePeExcel();

      if (!mounted) return;

      if (parsedTransactions == null) {
        setState(() {
          _isLoading = false;
        });

        return;
      }

      setState(() {
        transactions = parsedTransactions;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${parsedTransactions.length} '
              'transactions loaded.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _openReviewScreen() async {
    final reviewItems = ImportService.buildReviewItems();

    if (reviewItems.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No transactions are available for review.'),
          ),
        );

      return;
    }

    final shouldStartReview = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SmartSyncScreen(reviewItems: reviewItems),
      ),
    );

    if (!mounted || shouldStartReview != true) {
      return;
    }

    final selectedItems = await Navigator.push<List<ImportReviewItem>>(
      context,
      MaterialPageRoute(
        builder: (_) => ImportReviewScreen(initialItems: reviewItems),
      ),
    );

    if (!mounted || selectedItems == null) {
      return;
    }

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No expenses were selected.')),
        );

      return;
    }

    await _importSelectedExpenses(selectedItems);
  }

  Future<void> _importSelectedExpenses(
    List<ImportReviewItem> selectedItems,
  ) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ImportService.importReviewedExpenses(selectedItems);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Text('Import Complete'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ImportResultRow(
                  label: 'Expenses imported',
                  value: result.importedCount,
                  icon: Icons.receipt_long_outlined,
                ),
                const SizedBox(height: 12),
                _ImportResultRow(
                  label: 'Transactions skipped',
                  value: result.skippedCount,
                  icon: Icons.skip_next_outlined,
                ),
                const SizedBox(height: 12),
                _ImportResultRow(
                  label: 'Merchant rules saved',
                  value: result.rulesSavedCount,
                  icon: Icons.auto_awesome,
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      );

      ImportService.clear();

      if (!mounted) return;

      setState(() {
        transactions = [];
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to import transactions: '
            '$error';
      });
    }
  }

  void _clearImport() {
    ImportService.clear();

    setState(() {
      transactions = [];
      _errorMessage = null;
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final debitTransactions = transactions.where((transaction) {
      return transaction.isDebit;
    }).toList();

    final creditTransactions = transactions.where((transaction) {
      return transaction.isCredit;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Import PhonePe'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (transactions.isNotEmpty)
            IconButton(
              tooltip: 'Clear import',
              onPressed: _isLoading ? null : _clearImport,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImportFileCard(
              isLoading: _isLoading,
              hasTransactions: transactions.isNotEmpty,
              onPickFile: _pickFile,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _ErrorCard(message: _errorMessage!),
            ],

            if (transactions.isNotEmpty) ...[
              const SizedBox(height: 20),

              _ImportSummaryCard(
                totalTransactions: transactions.length,
                debitCount: debitTransactions.length,
                creditCount: creditTransactions.length,
                totalDebits: ImportService.totalDebits,
                totalCredits: ImportService.totalCredits,
              ),

              const SizedBox(height: 24),

              const Text(
                'Transaction Preview',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              ...transactions.take(25).map((transaction) {
                return _TransactionPreviewCard(
                  transaction: transaction,
                  formattedDate: _formatDate(transaction.date),
                  formattedAmount: _formatAmount(transaction.amount),
                );
              }),

              if (transactions.length > 25)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      'Showing first 25 of '
                      '${transactions.length} '
                      'transactions',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _openReviewScreen,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.fact_check_outlined),
                  label: Text(
                    _isLoading ? 'Processing...' : 'Review Transactions',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImportFileCard extends StatelessWidget {
  final bool isLoading;
  final bool hasTransactions;
  final VoidCallback onPickFile;

  const _ImportFileCard({
    required this.isLoading,
    required this.hasTransactions,
    required this.onPickFile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(
              Icons.upload_file_outlined,
              size: 72,
              color: Colors.indigo.shade300,
            ),
            const SizedBox(height: 14),
            const Text(
              'Import PhonePe Statement',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a PhonePe Excel '
              'statement. GuruPilot will '
              'read and preview the '
              'transactions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: isLoading ? null : onPickFile,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_open),
                label: Text(
                  isLoading
                      ? 'Reading file...'
                      : hasTransactions
                      ? 'Choose Another File'
                      : 'Choose Excel File',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportSummaryCard extends StatelessWidget {
  final int totalTransactions;
  final int debitCount;
  final int creditCount;
  final double totalDebits;
  final double totalCredits;

  const _ImportSummaryCard({
    required this.totalTransactions,
    required this.debitCount,
    required this.creditCount,
    required this.totalDebits,
    required this.totalCredits,
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
          const Text(
            'Import Summary',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalTransactions transactions',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  label: 'Debits',
                  value: debitCount.toString(),
                ),
              ),
              Expanded(
                child: _SummaryValue(
                  label: 'Credits',
                  value: creditCount.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  label: 'Debit Total',
                  value: '₹${totalDebits.toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _SummaryValue(
                  label: 'Credit Total',
                  value: '₹${totalCredits.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
        ],
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

class _TransactionPreviewCard extends StatelessWidget {
  final ImportTransaction transaction;
  final String formattedDate;
  final String formattedAmount;

  const _TransactionPreviewCard({
    required this.transaction,
    required this.formattedDate,
    required this.formattedAmount,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: isCredit
              ? Colors.green.shade100
              : Colors.red.shade100,
          child: Icon(
            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
            color: isCredit ? Colors.green.shade800 : Colors.red.shade800,
          ),
        ),
        title: Text(
          transaction.merchant,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$formattedDate\n'
          '${transaction.account ?? 'Unknown account'}',
        ),
        isThreeLine: true,
        trailing: Text(
          '${isCredit ? '+' : '-'}'
          '$formattedAmount',
          style: TextStyle(
            color: isCredit ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ImportResultRow extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _ImportResultRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
