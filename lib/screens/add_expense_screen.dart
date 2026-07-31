import 'package:flutter/material.dart';

import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddExpenseScreen({super.key, this.expense});

  bool get isEditing => expense != null;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late final TextEditingController titleController;
  late final TextEditingController amountController;

  late String selectedCategory;
  late DateTime selectedDate;

  final List<String> categories = const [
    'Food',
    'Fuel',
    'Shopping',
    'Bills',
    'Travel',
    'Medical',
    'Entertainment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    final existingExpense = widget.expense;

    titleController = TextEditingController(text: existingExpense?.title ?? '');

    amountController = TextEditingController(
      text: existingExpense?.amount.toStringAsFixed(2) ?? '',
    );

    selectedCategory = existingExpense?.category ?? 'Food';
    selectedDate = existingExpense?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      selectedDate = pickedDate;
    });
  }

  void _saveExpense() {
    final title = titleController.text.trim();
    final amount = double.tryParse(amountController.text.trim());

    if (title.isEmpty) {
      _showMessage('Please enter an expense title.');
      return;
    }

    if (amount == null || amount <= 0) {
      _showMessage('Please enter a valid amount.');
      return;
    }

    final expense = Expense(
      title: title,
      amount: amount,
      category: selectedCategory,
      date: selectedDate,
    );

    Navigator.pop(context, expense);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'Food':
        return '🍔 Food';
      case 'Fuel':
        return '⛽ Fuel';
      case 'Shopping':
        return '🛒 Shopping';
      case 'Bills':
        return '💡 Bills';
      case 'Travel':
        return '✈️ Travel';
      case 'Medical':
        return '💊 Medical';
      case 'Entertainment':
        return '🎬 Entertainment';
      default:
        return '📦 Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Expense' : 'Add Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Expense Title',
                prefixIcon: Icon(Icons.edit_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items: categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(_categoryLabel(category)),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade500),
              ),
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Expense Date'),
              subtitle: Text(
                '${selectedDate.day}/'
                '${selectedDate.month}/'
                '${selectedDate.year}',
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _selectDate,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveExpense,
                icon: Icon(widget.isEditing ? Icons.save : Icons.add),
                label: Text(
                  widget.isEditing ? 'Update Expense' : 'Save Expense',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
