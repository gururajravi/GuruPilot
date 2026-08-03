import 'package:flutter/material.dart';

import 'import_history_screen.dart';
import 'import_transactions_screen.dart';
import 'merchant_intelligence_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.upload_file_outlined),
                  ),
                  title: const Text('Import PhonePe Statement'),
                  subtitle: const Text(
                    'Import and review PhonePe '
                    'Excel transactions.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ImportTransactionsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),

                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.storefront_outlined),
                  ),
                  title: const Text('Merchant Intelligence'),
                  subtitle: const Text(
                    'View learned merchant rules and spending.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MerchantIntelligenceScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.history)),
                  title: const Text('Import History'),
                  subtitle: const Text('View completed import sessions.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ImportHistoryScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Privacy',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.lock_outline)),
              title: const Text('Local Data Storage'),
              subtitle: const Text(
                'Financial data is stored locally '
                'using Hive.',
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'GuruPilot v0.8',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}
