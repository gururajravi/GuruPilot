import 'package:flutter/material.dart';

import '../models/account.dart';

class AddAccountScreen extends StatefulWidget {
  final Account? account;

  const AddAccountScreen({super.key, this.account});

  bool get isEditing => account != null;

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  late final TextEditingController nameController;
  late final TextEditingController openingController;
  late final TextEditingController currentController;
  late final TextEditingController notesController;

  late String selectedType;

  bool isActive = true;

  final accountTypes = const [
    'Bank Account',
    'Credit Card',
    'Cash',
    'Wallet',
    'Loan',
    'Investment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    final account = widget.account;

    nameController = TextEditingController(text: account?.name ?? '');

    openingController = TextEditingController(
      text: account?.openingBalance.toString() ?? '',
    );

    currentController = TextEditingController(
      text: account?.currentBalance.toString() ?? '',
    );

    notesController = TextEditingController(text: account?.notes ?? '');

    selectedType = account?.type ?? 'Bank Account';

    isActive = account?.isActive ?? true;
  }

  @override
  void dispose() {
    nameController.dispose();
    openingController.dispose();
    currentController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _save() {
    final name = nameController.text.trim();

    final opening = double.tryParse(openingController.text);

    final current = double.tryParse(currentController.text);

    if (name.isEmpty) {
      _message('Enter account name');
      return;
    }

    if (opening == null) {
      _message('Enter opening balance');
      return;
    }

    if (current == null) {
      _message('Enter current balance');
      return;
    }

    final account = Account(
      name: name,
      type: selectedType,
      openingBalance: opening,
      currentBalance: current,
      createdDate: widget.account?.createdDate ?? DateTime.now(),
      isActive: isActive,
      notes: notesController.text.trim(),
    );

    Navigator.pop(context, account);
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Account' : 'Add Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: selectedType,
              decoration: const InputDecoration(
                labelText: 'Account Type',
                border: OutlineInputBorder(),
              ),
              items: accountTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
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
              controller: openingController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Opening Balance',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: currentController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Current Balance',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SwitchListTile(
              value: isActive,
              onChanged: (value) {
                setState(() {
                  isActive = value;
                });
              },
              title: const Text('Active Account'),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(
                  widget.isEditing ? 'Update Account' : 'Save Account',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
