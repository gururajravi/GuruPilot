import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  final List<Expense> expenses;
  final VoidCallback onExpensesChanged;

  const ExpensesScreen({
    super.key,
    required this.expenses,
    required this.onExpensesChanged,
  });

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedMonth = 'All';
  DateTime? _selectedDate;

  List<String> get _categories {
    final categories = widget.expenses
        .map((expense) => expense.category)
        .toSet()
        .toList();

    categories.sort();

    return ['All', ...categories];
  }

  List<String> get _months {
    final months = widget.expenses
        .map((expense) => _monthKey(expense.date))
        .toSet()
        .toList();

    months.sort((first, second) => second.compareTo(first));

    return ['All', ...months];
  }

  List<Expense> get _filteredExpenses {
    final filtered = widget.expenses.where((expense) {
      final titleMatches = expense.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );

      final categoryMatches =
          _selectedCategory == 'All' || expense.category == _selectedCategory;

      final monthMatches =
          _selectedMonth == 'All' || _monthKey(expense.date) == _selectedMonth;

      final dateMatches =
          _selectedDate == null || _isSameDate(expense.date, _selectedDate!);

      return titleMatches && categoryMatches && monthMatches && dateMatches;
    }).toList();

    filtered.sort((first, second) => second.date.compareTo(first.date));

    return filtered;
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

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  Future<void> _selectFilterDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      _selectedDate = pickedDate;
      _selectedMonth = _monthKey(pickedDate);
    });
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _selectedMonth = 'All';
      _selectedDate = null;
    });
  }

  Future<void> _editExpense(Expense expense) async {
    final updatedExpense = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(builder: (_) => AddExpenseScreen(expense: expense)),
    );

    if (updatedExpense == null) return;

    try {
      await ExpenseService.updateExpense(expense, updatedExpense);

      widget.onExpensesChanged();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense updated successfully.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update expense: $error')),
      );
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: Text('Delete "${expense.title}" permanently?'),
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
      await ExpenseService.deleteExpense(expense);

      widget.onExpensesChanged();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Expense deleted.')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete expense: $error')),
      );
    }
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = _filteredExpenses;

    final filteredTotal = filteredExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search expenses',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();

                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: const Icon(Icons.category_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(
                              category,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedMonth,
                        decoration: InputDecoration(
                          labelText: 'Month',
                          prefixIcon: const Icon(Icons.calendar_view_month),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: _months.map((month) {
                          return DropdownMenuItem<String>(
                            value: month,
                            child: Text(
                              _monthLabel(month),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _selectedMonth = value;

                            if (_selectedDate != null &&
                                value != 'All' &&
                                _monthKey(_selectedDate!) != value) {
                              _selectedDate = null;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _selectFilterDate,
                      icon: const Icon(Icons.event),
                      label: Text(
                        _selectedDate == null
                            ? 'Specific date'
                            : _formatDate(_selectedDate!),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(150, 48),
                      ),
                    ),
                    const Spacer(),
                    if (_searchQuery.isNotEmpty ||
                        _selectedCategory != 'All' ||
                        _selectedMonth != 'All' ||
                        _selectedDate != null)
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.filter_alt_off),
                        label: const Text('Clear filters'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${filteredExpenses.length} expense'
                    '${filteredExpenses.length == 1 ? '' : 's'}'
                    '${_selectedMonth == 'All' ? '' : ' • ${_monthLabel(_selectedMonth)}'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '₹${filteredTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredExpenses.isEmpty
                ? const Center(
                    child: Text(
                      'No matching expenses found.',
                      style: TextStyle(fontSize: 17),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = filteredExpenses[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade100,
                            child: Text(_categoryEmoji(expense.category)),
                          ),
                          title: Text(
                            expense.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${expense.category} • '
                            '${_formatDate(expense.date)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${expense.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editExpense(expense);
                                  }

                                  if (value == 'delete') {
                                    _deleteExpense(expense);
                                  }
                                },
                                itemBuilder: (_) => const [
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
                                ],
                              ),
                            ],
                          ),
                          onTap: () => _editExpense(expense),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
