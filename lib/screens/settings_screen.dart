import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/account.dart';
import '../models/expense.dart';
import '../models/import_history.dart';
import '../models/investment.dart';
import '../models/merchant_rule.dart';
import '../models/pending_transaction.dart';
import '../models/reviewed_transaction.dart';

import '../services/account_service.dart';
import '../services/backup_service.dart';
import '../services/expense_service.dart';
import '../services/import_history_service.dart';
import '../services/investment_service.dart';
import '../services/merchant_rule_service.dart';
import '../services/pending_transaction_service.dart';
import '../services/reviewed_transaction_service.dart';

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
  bool _isClearing = false;

  // ------------------------------------------------------------
  // Export Backup
  // ------------------------------------------------------------

  Future<void> _exportBackup() async {
    if (_isExporting) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final path = await BackupService.exportBackup();

      if (!mounted) {
        return;
      }

      if (path == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Backup export was cancelled.')),
          );

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

  // ------------------------------------------------------------
  // Restore Backup
  // ------------------------------------------------------------

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
            'For the safest restore, export a fresh '
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
                Expanded(child: Text('Restore Complete')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
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
                  const Divider(height: 28),
                  _RestoreResultRow(
                    label: 'Total Records',
                    value: result.total,
                    bold: true,
                  ),
                ],
              ),
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

  // ------------------------------------------------------------
  // Clear All Data
  // ------------------------------------------------------------

  Future<void> _clearAllData() async {
    if (_isClearing) {
      return;
    }

    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Expanded(child: Text('Clear all GuruPilot data?')),
            ],
          ),
          content: const Text(
            'This will permanently delete all locally '
            'stored:\n\n'
            '• Expenses\n'
            '• Investments\n'
            '• Merchant rules\n'
            '• Pending transactions\n'
            '• Accounts\n'
            '• Reviewed transactions\n'
            '• Import history\n\n'
            'Export a backup before continuing.',
          ),
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
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (firstConfirm != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Final confirmation'),
          content: const Text(
            'This action cannot be undone unless '
            'you have a valid GuruPilot backup.\n\n'
            'Are you absolutely sure you want to '
            'delete everything?',
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
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete Everything'),
            ),
          ],
        );
      },
    );

    if (secondConfirm != true) {
      return;
    }

    setState(() {
      _isClearing = true;
    });

    try {
      await Hive.box<Expense>(ExpenseService.boxName).clear();

      await Hive.box<Investment>(InvestmentService.boxName).clear();

      await Hive.box<MerchantRule>(MerchantRuleService.boxName).clear();

      await Hive.box<PendingTransaction>(
        PendingTransactionService.boxName,
      ).clear();

      await Hive.box<Account>(AccountService.boxName).clear();

      await Hive.box<ReviewedTransaction>(
        ReviewedTransactionService.boxName,
      ).clear();

      await Hive.box<ImportHistory>(ImportHistoryService.boxName).clear();

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green),
                SizedBox(width: 10),
                Text('Data Cleared'),
              ],
            ),
            content: const Text(
              'All local GuruPilot data has been '
              'deleted successfully.\n\n'
              'You can now restore your backup from '
              'Settings → Restore Backup.',
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
          const SnackBar(
            content: Text('All local GuruPilot data has been cleared.'),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Unable to clear data: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final operationInProgress = _isExporting || _isRestoring || _isClearing;

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
                  enabled: !operationInProgress,
                  leading: const CircleAvatar(
                    child: Icon(Icons.upload_file_outlined),
                  ),
                  title: const Text('Import PhonePe Statement'),
                  subtitle: const Text(
                    'Import and review PhonePe '
                    'Excel transactions.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: operationInProgress
                      ? null
                      : () {
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
                  enabled: !operationInProgress,
                  leading: const CircleAvatar(child: Icon(Icons.history)),
                  title: const Text('Import History'),
                  subtitle: const Text('View completed import sessions.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: operationInProgress
                      ? null
                      : () {
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
                  enabled: !operationInProgress,
                  leading: const CircleAvatar(
                    child: Icon(Icons.storefront_outlined),
                  ),
                  title: const Text('Merchant Intelligence'),
                  subtitle: const Text(
                    'View learned merchant rules '
                    'and spending insights.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: operationInProgress
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const MerchantIntelligenceScreen(),
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
                  enabled: !operationInProgress,
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
                  onTap: operationInProgress ? null : _exportBackup,
                ),

                const Divider(height: 1),

                ListTile(
                  enabled: !operationInProgress,
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
                  onTap: operationInProgress ? null : _restoreBackup,
                ),

                const Divider(height: 1),

                ListTile(
                  enabled: !operationInProgress,
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade50,
                    child: _isClearing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.delete_forever_outlined,
                            color: Colors.red.shade700,
                          ),
                  ),
                  title: Text(
                    _isClearing ? 'Clearing Data...' : 'Clear All Data',
                  ),
                  subtitle: const Text(
                    'Delete all locally stored '
                    'GuruPilot data.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: operationInProgress ? null : _clearAllData,
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
                      'Backup files contain your '
                      'financial information. Store '
                      'them in a private and secure '
                      'location.',
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

          const Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(Icons.lock_outline)),
              title: Text('Local Data Storage'),
              subtitle: Text(
                'GuruPilot stores financial '
                'data locally using Hive.',
              ),
            ),
          ),

          const SizedBox(height: 30),

          // ------------------------------------------------------
          // App Version
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
                  'Backup format '
                  'v${BackupService.backupVersion}',
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

// --------------------------------------------------------------
// Section Title
// --------------------------------------------------------------

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

// --------------------------------------------------------------
// Restore Result Row
// --------------------------------------------------------------

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
