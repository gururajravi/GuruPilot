import 'package:flutter/material.dart';

import '../models/investment.dart';

class AddInvestmentScreen extends StatefulWidget {
  final Investment? investment;

  const AddInvestmentScreen({super.key, this.investment});

  bool get isEditing => investment != null;

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  late final TextEditingController titleController;
  late final TextEditingController investedAmountController;
  late final TextEditingController currentValueController;
  late final TextEditingController notesController;

  late String selectedType;
  late String selectedOwner;
  late DateTime selectedDate;

  final List<String> investmentTypes = const [
    'Mutual Fund',
    'Chit Fund',
    'Stock',
    'Gold',
    'Property',
    'LIC',
    'Fixed Deposit',
    'EPF',
    'PPF',
    'NPS',
    'Other',
  ];

  final List<String> owners = const ['Guru', 'Ananya', 'Shared'];

  @override
  void initState() {
    super.initState();

    final existingInvestment = widget.investment;

    titleController = TextEditingController(
      text: existingInvestment?.title ?? '',
    );

    investedAmountController = TextEditingController(
      text: existingInvestment?.investedAmount.toStringAsFixed(2) ?? '',
    );

    currentValueController = TextEditingController(
      text: existingInvestment?.currentValue.toStringAsFixed(2) ?? '',
    );

    notesController = TextEditingController(
      text: existingInvestment?.notes ?? '',
    );

    selectedType = investmentTypes.contains(existingInvestment?.type)
        ? existingInvestment!.type
        : 'Mutual Fund';

    selectedOwner = owners.contains(existingInvestment?.owner)
        ? existingInvestment!.owner
        : 'Guru';

    selectedDate = existingInvestment?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    titleController.dispose();
    investedAmountController.dispose();
    currentValueController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2035),
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      selectedDate = pickedDate;
    });
  }

  void _saveInvestment() {
    final title = titleController.text.trim();

    final investedAmount = double.tryParse(
      investedAmountController.text.trim().replaceAll(',', ''),
    );

    final currentValueText = currentValueController.text.trim().replaceAll(
      ',',
      '',
    );

    final currentValue = currentValueText.isEmpty
        ? investedAmount
        : double.tryParse(currentValueText);

    if (title.isEmpty) {
      _showMessage('Please enter an investment title.');
      return;
    }

    if (investedAmount == null || investedAmount < 0) {
      _showMessage('Please enter a valid invested amount.');
      return;
    }

    if (currentValue == null || currentValue < 0) {
      _showMessage('Please enter a valid current value.');
      return;
    }

    final investment = Investment(
      title: title,
      type: selectedType,
      investedAmount: investedAmount,
      currentValue: currentValue,
      date: selectedDate,
      owner: selectedOwner,
      notes: notesController.text.trim(),
    );

    Navigator.pop(context, investment);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'Mutual Fund':
        return '📈 Mutual Fund';
      case 'Chit Fund':
        return '🤝 Chit Fund';
      case 'Stock':
        return '📊 Stock';
      case 'Gold':
        return '🪙 Gold';
      case 'Property':
        return '🏠 Property';
      case 'LIC':
        return '🛡️ LIC';
      case 'Fixed Deposit':
        return '🏦 Fixed Deposit';
      case 'EPF':
        return '💼 EPF';
      case 'PPF':
        return '💰 PPF';
      case 'NPS':
        return '📅 NPS';
      default:
        return '📦 Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Investment' : 'Add Investment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Investment Title',
                hintText: 'Example: SBI Mutual Fund',
                prefixIcon: Icon(Icons.edit_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              decoration: const InputDecoration(
                labelText: 'Investment Type',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                border: OutlineInputBorder(),
              ),
              items: investmentTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(_typeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedType = value;
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: investedAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Invested Amount',
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: currentValueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Current Value (Optional)',
                hintText: 'Leave blank to use invested amount',
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.trending_up),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: selectedOwner,
              decoration: const InputDecoration(
                labelText: 'Owner',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              items: owners.map((owner) {
                return DropdownMenuItem<String>(
                  value: owner,
                  child: Text(owner),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedOwner = value;
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
              title: const Text('Investment Date'),
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
                hintText: 'Optional details',
                prefixIcon: Icon(Icons.notes_outlined),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveInvestment,
                icon: Icon(widget.isEditing ? Icons.save : Icons.add),
                label: Text(
                  widget.isEditing ? 'Update Investment' : 'Save Investment',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
