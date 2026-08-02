import 'package:flutter/material.dart';

import 'import_transactions_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openPhonePeImport(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ImportTransactionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Data & Imports',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade100,
                child: const Icon(
                  Icons.upload_file_outlined,
                  color: Colors.indigo,
                ),
              ),
              title: const Text(
                'Import PhonePe Statement',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Choose a PhonePe Excel statement and preview transactions.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _openPhonePeImport(context);
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.account_balance_wallet_outlined),
              ),
              title: Text(
                'GuruPilot',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Personal finance and expense tracking app'),
            ),
          ),
        ],
      ),
    );
  }
}
