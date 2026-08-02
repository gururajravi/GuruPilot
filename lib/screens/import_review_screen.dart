import 'package:flutter/material.dart';

import '../models/import_review_item.dart';

class ImportReviewScreen extends StatefulWidget {
  final List<ImportReviewItem> initialItems;

  const ImportReviewScreen({super.key, required this.initialItems});

  @override
  State<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends State<ImportReviewScreen> {
  late List<ImportReviewItem> reviewItems;

  final List<String> categories = const [
    'Food',
    'Guru Office Food',
    'Bike',
    'Grocery',
    'Car',
    'Miscellaneous',
    'Guru Personal',
    'Ananya Personal',
    'Shopping',
    'Bills',
    'Travel',
    'Fuel',
    'Medical',
    'Entertainment',
    'Personal',
    'Other',
    'Uncategorized',
  ];

  final List<String> people = const ['Guru', 'Ananya', 'Shared'];

  final List<String> paymentMethods = const [
    'UPI',
    'Cash',
    'Card',
    'Bank',
    'Unknown',
  ];

  @override
  void initState() {
    super.initState();

    reviewItems = List<ImportReviewItem>.from(widget.initialItems);
  }

  int get _selectedCount {
    return reviewItems.where((item) {
      return item.shouldImport &&
          !item.isDuplicate &&
          item.transactionType == ImportTransactionType.expense;
    }).length;
  }

  int get _duplicateCount {
    return reviewItems.where((item) {
      return item.isDuplicate;
    }).length;
  }

  int get _uncategorizedCount {
    return reviewItems.where((item) {
      return item.shouldImport &&
          !item.isDuplicate &&
          item.transactionType == ImportTransactionType.expense &&
          item.category == 'Uncategorized';
    }).length;
  }

  int get _transferCount {
    return reviewItems.where((item) {
      return item.transactionType == ImportTransactionType.transfer;
    }).length;
  }

  int get _incomeCount {
    return reviewItems.where((item) {
      return item.transactionType == ImportTransactionType.income;
    }).length;
  }

  void _updateItem(int index, ImportReviewItem updatedItem) {
    setState(() {
      reviewItems[index] = updatedItem;
    });
  }

  void _selectAllExpenses() {
    setState(() {
      reviewItems = reviewItems.map((item) {
        if (item.isDuplicate ||
            item.transactionType != ImportTransactionType.expense) {
          return item.copyWith(shouldImport: false);
        }

        return item.copyWith(shouldImport: true);
      }).toList();
    });
  }

  void _selectCategorizedOnly() {
    setState(() {
      reviewItems = reviewItems.map((item) {
        final canSelect =
            !item.isDuplicate &&
            item.transactionType == ImportTransactionType.expense &&
            item.category != 'Uncategorized';

        return item.copyWith(shouldImport: canSelect);
      }).toList();
    });
  }

  void _clearSelection() {
    setState(() {
      reviewItems = reviewItems.map((item) {
        return item.copyWith(shouldImport: false);
      }).toList();
    });
  }

  void _continueImport() {
    final selectedItems = reviewItems.where((item) {
      return item.shouldImport &&
          !item.isDuplicate &&
          item.transactionType == ImportTransactionType.expense;
    }).toList();

    if (selectedItems.isEmpty) {
      _showMessage('Select at least one expense to import.');

      return;
    }

    final uncategorizedSelected = selectedItems.where((item) {
      return item.category == 'Uncategorized';
    }).length;

    if (uncategorizedSelected > 0) {
      _showMessage(
        '$uncategorizedSelected selected transaction'
        '${uncategorizedSelected == 1 ? '' : 's'} '
        'still need a category.',
      );

      return;
    }

    Navigator.pop(context, selectedItems);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _transactionTypeLabel(ImportTransactionType type) {
    switch (type) {
      case ImportTransactionType.expense:
        return 'Expense';

      case ImportTransactionType.transfer:
        return 'Transfer';

      case ImportTransactionType.income:
        return 'Income';

      case ImportTransactionType.refund:
        return 'Refund';

      case ImportTransactionType.unknown:
        return 'Unknown';
    }
  }

  IconData _transactionTypeIcon(ImportTransactionType type) {
    switch (type) {
      case ImportTransactionType.expense:
        return Icons.shopping_cart_outlined;

      case ImportTransactionType.transfer:
        return Icons.swap_horiz;

      case ImportTransactionType.income:
        return Icons.south_west;

      case ImportTransactionType.refund:
        return Icons.replay;

      case ImportTransactionType.unknown:
        return Icons.help_outline;
    }
  }

  Color _transactionTypeColor(ImportTransactionType type) {
    switch (type) {
      case ImportTransactionType.expense:
        return Colors.red;

      case ImportTransactionType.transfer:
        return Colors.orange;

      case ImportTransactionType.income:
        return Colors.green;

      case ImportTransactionType.refund:
        return Colors.blue;

      case ImportTransactionType.unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Review Transactions'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'select_all':
                  _selectAllExpenses();

                case 'select_categorized':
                  _selectCategorizedOnly();

                case 'clear':
                  _clearSelection();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'select_all',
                child: Text('Select all expenses'),
              ),
              PopupMenuItem<String>(
                value: 'select_categorized',
                child: Text('Select categorized only'),
              ),
              PopupMenuItem<String>(
                value: 'clear',
                child: Text('Clear selection'),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _selectedCount == 0 ? null : _continueImport,
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                'Continue with $_selectedCount '
                'expense${_selectedCount == 1 ? '' : 's'}',
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _ReviewSummary(
            selectedCount: _selectedCount,
            duplicateCount: _duplicateCount,
            uncategorizedCount: _uncategorizedCount,
            transferCount: _transferCount,
            incomeCount: _incomeCount,
          ),
          if (_uncategorizedCount > 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade900),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$_uncategorizedCount selected '
                      'transaction'
                      '${_uncategorizedCount == 1 ? '' : 's'} '
                      'still need a category.',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: reviewItems.length,
              itemBuilder: (context, index) {
                final item = reviewItems[index];

                return _ReviewItemCard(
                  key: ValueKey(
                    'review-card-'
                    '${item.transaction.transactionId}',
                  ),
                  item: item,
                  categories: categories,
                  people: people,
                  paymentMethods: paymentMethods,
                  formattedDate: _formatDate(item.transaction.date),
                  formattedAmount: _formatAmount(item.transaction.amount),
                  transactionTypeLabel: _transactionTypeLabel(
                    item.transactionType,
                  ),
                  transactionTypeIcon: _transactionTypeIcon(
                    item.transactionType,
                  ),
                  transactionTypeColor: _transactionTypeColor(
                    item.transactionType,
                  ),
                  onChanged: (updatedItem) {
                    _updateItem(index, updatedItem);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  final int selectedCount;
  final int duplicateCount;
  final int uncategorizedCount;
  final int transferCount;
  final int incomeCount;

  const _ReviewSummary({
    required this.selectedCount,
    required this.duplicateCount,
    required this.uncategorizedCount,
    required this.transferCount,
    required this.incomeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        children: [
          _SummaryMetric(label: 'Selected', value: selectedCount),
          _SummaryMetric(label: 'Uncategorized', value: uncategorizedCount),
          _SummaryMetric(label: 'Duplicates', value: duplicateCount),
          _SummaryMetric(label: 'Transfers', value: transferCount),
          _SummaryMetric(label: 'Income', value: incomeCount),
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
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
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

class _ReviewItemCard extends StatelessWidget {
  final ImportReviewItem item;
  final List<String> categories;
  final List<String> people;
  final List<String> paymentMethods;
  final String formattedDate;
  final String formattedAmount;
  final String transactionTypeLabel;
  final IconData transactionTypeIcon;
  final Color transactionTypeColor;
  final ValueChanged<ImportReviewItem> onChanged;

  const _ReviewItemCard({
    super.key,
    required this.item,
    required this.categories,
    required this.people,
    required this.paymentMethods,
    required this.formattedDate,
    required this.formattedAmount,
    required this.transactionTypeLabel,
    required this.transactionTypeIcon,
    required this.transactionTypeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final transactionId = item.transaction.transactionId;

    final canImport =
        !item.isDuplicate &&
        item.transactionType == ImportTransactionType.expense;

    final safeCategory = categories.contains(item.category)
        ? item.category
        : 'Uncategorized';

    final safePerson = people.contains(item.person) ? item.person : 'Shared';

    final safePayment = paymentMethods.contains(item.paymentMethod)
        ? item.paymentMethod
        : 'UPI';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: item.shouldImport && canImport,
                  onChanged: canImport
                      ? (value) {
                          onChanged(
                            item.copyWith(shouldImport: value ?? false),
                          );
                        }
                      : null,
                ),
                CircleAvatar(
                  backgroundColor: transactionTypeColor.withValues(alpha: 0.14),
                  child: Icon(transactionTypeIcon, color: transactionTypeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.transaction.merchant,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$formattedDate • '
                        '$transactionTypeLabel',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      if (item.transaction.account != null)
                        Text(
                          item.transaction.account!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        transactionId,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formattedAmount,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: item.transaction.isCredit
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),

            if (item.isDuplicate) ...[
              const SizedBox(height: 12),
              _StatusBanner(
                icon: Icons.content_copy,
                text:
                    'Already exists in expenses. '
                    'It will not be imported.',
                background: Colors.orange.shade50,
                foreground: Colors.orange.shade900,
              ),
            ],

            const SizedBox(height: 14),

            DropdownButtonFormField<ImportTransactionType>(
              key: ValueKey(
                'type-$transactionId-'
                '${item.transactionType.name}',
              ),
              initialValue: item.transactionType,
              decoration: const InputDecoration(
                labelText: 'Transaction Type',
                prefixIcon: Icon(Icons.compare_arrows),
                border: OutlineInputBorder(),
              ),
              items: ImportTransactionType.values.map((type) {
                return DropdownMenuItem<ImportTransactionType>(
                  value: type,
                  child: Text(_typeLabel(type)),
                );
              }).toList(),
              onChanged: item.isDuplicate
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }

                      final isExpense = value == ImportTransactionType.expense;

                      onChanged(
                        item.copyWith(
                          transactionType: value,
                          shouldImport: isExpense,
                          rememberMerchant: isExpense,
                        ),
                      );
                    },
            ),

            if (item.transactionType == ImportTransactionType.expense) ...[
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                key: ValueKey(
                  'category-$transactionId-'
                  '$safeCategory',
                ),
                initialValue: safeCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: item.isDuplicate
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        onChanged(item.copyWith(category: value));
                      },
              ),

              const SizedBox(height: 14),

              LayoutBuilder(
                builder: (context, constraints) {
                  final useColumn = constraints.maxWidth < 520;

                  final personDropdown = DropdownButtonFormField<String>(
                    key: ValueKey(
                      'person-$transactionId-'
                      '$safePerson',
                    ),
                    initialValue: safePerson,
                    decoration: const InputDecoration(
                      labelText: 'Expense For',
                      border: OutlineInputBorder(),
                    ),
                    items: people.map((person) {
                      return DropdownMenuItem<String>(
                        value: person,
                        child: Text(person),
                      );
                    }).toList(),
                    onChanged: item.isDuplicate
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }

                            onChanged(item.copyWith(person: value));
                          },
                  );

                  final paymentDropdown = DropdownButtonFormField<String>(
                    key: ValueKey(
                      'payment-$transactionId-'
                      '$safePayment',
                    ),
                    initialValue: safePayment,
                    decoration: const InputDecoration(
                      labelText: 'Payment',
                      border: OutlineInputBorder(),
                    ),
                    items: paymentMethods.map((method) {
                      return DropdownMenuItem<String>(
                        value: method,
                        child: Text(method),
                      );
                    }).toList(),
                    onChanged: item.isDuplicate
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }

                            onChanged(item.copyWith(paymentMethod: value));
                          },
                  );

                  if (useColumn) {
                    return Column(
                      children: [
                        personDropdown,
                        const SizedBox(height: 12),
                        paymentDropdown,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: personDropdown),
                      const SizedBox(width: 10),
                      Expanded(child: paymentDropdown),
                    ],
                  );
                },
              ),

              const SizedBox(height: 8),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: item.rememberMerchant,
                onChanged: item.isDuplicate
                    ? null
                    : (value) {
                        onChanged(item.copyWith(rememberMerchant: value));
                      },
                title: const Text('Remember this merchant mapping'),
                subtitle: const Text(
                  'Future imports can use this '
                  'category automatically.',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _typeLabel(ImportTransactionType type) {
    switch (type) {
      case ImportTransactionType.expense:
        return 'Expense';

      case ImportTransactionType.transfer:
        return 'Transfer';

      case ImportTransactionType.income:
        return 'Income';

      case ImportTransactionType.refund:
        return 'Refund';

      case ImportTransactionType.unknown:
        return 'Unknown';
    }
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  const _StatusBanner({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }
}
