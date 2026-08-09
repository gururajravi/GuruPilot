import 'package:flutter/material.dart';

import '../services/backup_service.dart';
import 'import_history_screen.dart';
import 'import_transactions_screen.dart';
import 'merchant_intelligence_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isRestoring = false;

  Future<void> _exportBackup() async {
    if (_isExporting) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      await BackupService.exportBackup();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('GuruPilot backup created successfully.'),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Backup failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _restoreBackup() async {
    if (_isRestoring) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Restore GuruPilot backup?'),
          content: const Text(
            'The selected backup will be merged '
            'with the data currently stored in GuruPilot.\n\n'
            'For the safest full restore, export a fresh '
            'backup before continuing.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.restore),
              label: const Text('Choose Backup'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isRestoring = true;
    });

    try {
      final jsonText = await BackupService.pickBackupFile();

      if (jsonText == null) {
        return;
      }

      final result = await BackupService.restoreFromJson(jsonText);

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Text('Restore Complete'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RestoreResultRow(label: 'Expenses', value: result.expenses),
                _RestoreResultRow(
                  label: 'Investments',
                  value: result.investments,
                ),
                _RestoreResultRow(
                  label: 'Merchant Rules',
                  value: result.merchantRules,
                ),
                _RestoreResultRow(
                  label: 'Pending Transactions',
                  value: result.pendingTransactions,
                ),
                _RestoreResultRow(label: 'Accounts', value: result.accounts),
                _RestoreResultRow(
                  label: 'Reviewed Transactions',
                  value: result.reviewedTransactions,
                ),
                _RestoreResultRow(
                  label: 'Import History',
                  value: result.importHistory,
                ),
                const Divider(height: 26),
                _RestoreResultRow(
                  label: 'Total Records',
                  value: result.total,
                  bold: true,
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

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Backup restored successfully.')),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Restore failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // ------------------------------------------------------
          // Data & Imports
          // ------------------------------------------------------
          const _SectionTitle(title: 'Data & Imports'),

          const SizedBox(height: 10),

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

                const Divider(height: 1),

                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.storefront_outlined),
                  ),
                  title: const Text('Merchant Intelligence'),
                  subtitle: const Text(
                    'View learned merchant rules '
                    'and spending insights.',
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
              ],
            ),
          ),

          const SizedBox(height: 26),

          // ------------------------------------------------------
          // Backup & Restore
          // ------------------------------------------------------
          const _SectionTitle(title: 'Backup & Restore'),

          const SizedBox(height: 10),

          Card(
            child: Column(
              children: [
                ListTile(
                  enabled: !_isExporting,
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade50,
                    child: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.file_download_outlined,
                            color: Colors.green.shade700,
                          ),
                  ),
                  title: Text(
                    _isExporting ? 'Creating Backup...' : 'Export Backup',
                  ),
                  subtitle: const Text(
                    'Save all GuruPilot data '
                    'to a JSON backup file.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _isExporting ? null : _exportBackup,
                ),

                const Divider(height: 1),

                ListTile(
                  enabled: !_isRestoring,
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: _isRestoring
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.restore_outlined,
                            color: Colors.blue.shade700,
                          ),
                  ),
                  title: Text(
                    _isRestoring ? 'Restoring Backup...' : 'Restore Backup',
                  ),
                  subtitle: const Text(
                    'Restore GuruPilot data from '
                    'a previously exported JSON file.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _isRestoring ? null : _restoreBackup,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security_outlined, color: Colors.amber.shade900),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Backups contain your financial '
                      'information. Store backup files '
                      'in a private and secure location.',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 26),

          // ------------------------------------------------------
          // Privacy
          // ------------------------------------------------------
          const _SectionTitle(title: 'Privacy'),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.lock_outline)),
              title: const Text('Local Data Storage'),
              subtitle: const Text(
                'GuruPilot stores your financial '
                'data locally using Hive.',
              ),
            ),
          ),

          const SizedBox(height: 30),

          // ------------------------------------------------------
          // Version
          // ------------------------------------------------------
          Center(
            child: Column(
              children: [
                Text(
                  'GuruPilot',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Backup format v${BackupService.backupVersion}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class _RestoreResultRow extends StatelessWidget {
  final String label;
  final int value;
  final bool bold;

  const _RestoreResultRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            value.toString(),
            style: style.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
