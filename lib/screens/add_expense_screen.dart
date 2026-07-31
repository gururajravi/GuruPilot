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
  late final TextEditingController merchantController;
  late final TextEditingController transactionIdController;
  late final TextEditingController notesController;

  late String selectedCategory;
  late String selectedPaymentMethod;
  late String selectedPerson;
  late DateTime selectedDate;

  final List<String> categories = const [
    'Food',
    'Fuel',
    'Grocery',
    'Shopping',
    'Bills',
    'Travel',
    'Medical',
    'Entertainment',
    'Personal',
    'Other',
    'Uncategorized',
  ];

  final List<String> paymentMethods = const [
    'UPI',
    'Cash',
    'Card',
    'Bank',
    'Unknown',
  ];

  final List<String> people = const ['Guru', 'Ananya', 'Shared'];

  @override
  void initState() {
    super.initState();

    final existingExpense = widget.expense;

    titleController = TextEditingController(text: existingExpense?.title ?? '');

    amountController = TextEditingController(
      text: existingExpense?.amount.toStringAsFixed(2) ?? '',
    );

    merchantController = TextEditingController(
      text: existingExpense?.merchant ?? '',
    );

    transactionIdController = TextEditingController(
      text: existingExpense?.transactionId ?? '',
    );

    notesController = TextEditingController(text: existingExpense?.notes ?? '');

    selectedCategory = _validCategory(existingExpense?.category ?? 'Food');

    selectedPaymentMethod = _validPaymentMethod(
      existingExpense?.paymentMethod ?? 'Unknown',
    );

    selectedPerson = _validPerson(existingExpense?.person ?? 'Shared');

    selectedDate = existingExpense?.date ?? DateTime.now();
  }

  String _validCategory(String category) {
    return categories.contains(category) ? category : 'Other';
  }

  String _validPaymentMethod(String paymentMethod) {
    return paymentMethods.contains(paymentMethod) ? paymentMethod : 'Unknown';
  }

  String _validPerson(String person) {
    return people.contains(person) ? person : 'Shared';
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    merchantController.dispose();
    transactionIdController.dispose();
    notesController.dispose();
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
    final amountText = amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountText);

    if (title.isEmpty) {
      _showMessage('Please enter an expense title.');
      return;
    }

    if (amount == null || amount <= 0) {
      _showMessage('Please enter a valid amount.');
      return;
    }

    final merchant = merchantController.text.trim();
    final transactionId = transactionIdController.text.trim();
    final notes = notesController.text.trim();

    final expense = Expense(
      title: title,
      amount: amount,
      category: selectedCategory,
      date: selectedDate,
      merchant: merchant.isEmpty ? null : merchant,
      paymentMethod: selectedPaymentMethod,
      source: widget.expense?.source ?? 'manual',
      person: selectedPerson,
      transactionId: transactionId.isEmpty ? null : transactionId,
      isCategorized: selectedCategory != 'Uncategorized',
      notes: notes.isEmpty ? null : notes,
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
      case 'Grocery':
        return '🛍️ Grocery';
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
      case 'Personal':
        return '👤 Personal';
      case 'Uncategorized':
        return '❓ Uncategorized';
      default:
        return '📦 Other';
    }
  }

  IconData _paymentMethodIcon(String paymentMethod) {
    switch (paymentMethod) {
      case 'UPI':
        return Icons.qr_code_2;
      case 'Cash':
        return Icons.payments_outlined;
      case 'Card':
        return Icons.credit_card;
      case 'Bank':
        return Icons.account_balance_outlined;
      default:
        return Icons.help_outline;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Expense Title',
                hintText: 'Example: Dinner, Petrol, Wi-Fi bill',
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

            DropdownButtonFormField<String>(
              initialValue: selectedPaymentMethod,
              decoration: InputDecoration(
                labelText: 'Payment Method',
                prefixIcon: Icon(_paymentMethodIcon(selectedPaymentMethod)),
                border: const OutlineInputBorder(),
              ),
              items: paymentMethods.map((paymentMethod) {
                return DropdownMenuItem<String>(
                  value: paymentMethod,
                  child: Text(paymentMethod),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedPaymentMethod = value;
                });
              },
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: selectedPerson,
              decoration: const InputDecoration(
                labelText: 'Expense For',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              items: people.map((person) {
                return DropdownMenuItem<String>(
                  value: person,
                  child: Text(person),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedPerson = value;
                });
              },
            ),
            const SizedBox(height: 20),

            TextField(
              controller: merchantController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Merchant',
                hintText: 'Example: Swiggy, BESCOM, Shell',
                prefixIcon: Icon(Icons.store_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: transactionIdController,
              decoration: const InputDecoration(
                labelText: 'Transaction ID',
                hintText: 'Optional UPI or bank transaction ID',
                prefixIcon: Icon(Icons.receipt_long_outlined),
                border: OutlineInputBorder(),
              ),
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
            const SizedBox(height: 20),

            TextField(
              controller: notesController,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional additional information',
                prefixIcon: Icon(Icons.notes_outlined),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
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
