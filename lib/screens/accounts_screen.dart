import 'package:flutter/material.dart';

import '../models/account.dart';
import '../services/account_service.dart';
import 'add_account_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<Account> accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    setState(() {
      accounts = AccountService.getAccounts();
    });
  }

  Future<void> _addAccount() async {
    final account = await Navigator.push<Account>(
      context,
      MaterialPageRoute(builder: (_) => const AddAccountScreen()),
    );

    if (account == null) return;

    try {
      await AccountService.addAccount(account);

      if (!mounted) return;

      _loadAccounts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account added successfully.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to add account: $error')));
    }
  }

  Future<void> _editAccount(Account account) async {
    final updatedAccount = await Navigator.push<Account>(
      context,
      MaterialPageRoute(builder: (_) => AddAccountScreen(account: account)),
    );

    if (updatedAccount == null) return;

    try {
      await AccountService.updateAccount(account, updatedAccount);

      if (!mounted) return;

      _loadAccounts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account updated successfully.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update account: $error')),
      );
    }
  }

  Future<void> _deleteAccount(Account account) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Text('Delete "${account.name}" permanently?'),
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
      await AccountService.deleteAccount(account);

      if (!mounted) return;

      _loadAccounts();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account deleted.')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete account: $error')),
      );
    }
  }

  IconData _accountIcon(String type) {
    switch (type) {
      case 'Bank Account':
        return Icons.account_balance;
      case 'Credit Card':
        return Icons.credit_card;
      case 'Cash':
        return Icons.payments_outlined;
      case 'Wallet':
        return Icons.account_balance_wallet_outlined;
      case 'Loan':
        return Icons.request_quote_outlined;
      case 'Investment':
        return Icons.trending_up;
      default:
        return Icons.account_box_outlined;
    }
  }

  String _balanceLabel(Account account) {
    if (account.type == 'Credit Card') {
      return 'Outstanding';
    }

    if (account.type == 'Loan') {
      return 'Outstanding';
    }

    return 'Balance';
  }

  Color _balanceColor(Account account) {
    if (account.type == 'Credit Card' || account.type == 'Loan') {
      return Colors.red;
    }

    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final activeAccounts = accounts
        .where((account) => account.isActive)
        .toList();

    final bankBalance = activeAccounts
        .where((account) => account.type == 'Bank Account')
        .fold<double>(0, (sum, account) => sum + account.currentBalance);

    final cashBalance = activeAccounts
        .where((account) => account.type == 'Cash')
        .fold<double>(0, (sum, account) => sum + account.currentBalance);

    final creditCardOutstanding = activeAccounts
        .where((account) => account.type == 'Credit Card')
        .fold<double>(0, (sum, account) => sum + account.currentBalance.abs());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Accounts'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAccount,
        child: const Icon(Icons.add),
      ),
      body: accounts.isEmpty
          ? _EmptyAccounts(onAddAccount: _addAccount)
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AccountsSummaryCard(
                    bankBalance: bankBalance,
                    cashBalance: cashBalance,
                    creditCardOutstanding: creditCardOutstanding,
                    activeCount: activeAccounts.length,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Your Accounts',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...accounts.map(
                    (account) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: CircleAvatar(
                          backgroundColor: account.isActive
                              ? Colors.indigo.shade100
                              : Colors.grey.shade300,
                          child: Icon(
                            _accountIcon(account.type),
                            color: account.isActive
                                ? Colors.indigo
                                : Colors.grey.shade700,
                          ),
                        ),
                        title: Text(
                          account.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: account.isActive ? null : Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          '${account.type} • '
                          '${account.isActive ? 'Active' : 'Inactive'}\n'
                          '${_balanceLabel(account)}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${account.currentBalance.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _balanceColor(account),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editAccount(account);
                                }

                                if (value == 'delete') {
                                  _deleteAccount(account);
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
                        onTap: () {
                          _editAccount(account);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AccountsSummaryCard extends StatelessWidget {
  final double bankBalance;
  final double cashBalance;
  final double creditCardOutstanding;
  final int activeCount;

  const _AccountsSummaryCard({
    required this.bankBalance,
    required this.cashBalance,
    required this.creditCardOutstanding,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Overview',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            '₹${(bankBalance + cashBalance).toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Available funds',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryValue(label: 'Bank', value: bankBalance),
              ),
              Expanded(
                child: _SummaryValue(label: 'Cash', value: cashBalance),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  label: 'Credit Cards',
                  value: creditCardOutstanding,
                ),
              ),
              Expanded(
                child: _SummaryText(
                  label: 'Active Accounts',
                  value: activeCount.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final String label;
  final double value;

  const _SummaryValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SummaryText extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  final VoidCallback onAddAccount;

  const _EmptyAccounts({required this.onAddAccount});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 82,
              color: Colors.indigo.shade200,
            ),
            const SizedBox(height: 18),
            const Text(
              'No accounts added',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add bank accounts, credit cards, cash, '
              'wallets and loans.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAddAccount,
              icon: const Icon(Icons.add),
              label: const Text('Add Account'),
            ),
          ],
        ),
      ),
    );
  }
}
