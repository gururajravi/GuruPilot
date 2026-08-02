import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';

import 'accounts_screen.dart';
import 'add_expense_screen.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'expenses_screen.dart';
import 'investments_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Expense> expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() {
    final loadedExpenses = ExpenseService.getExpenses();

    debugPrint('HomeScreen loaded ${loadedExpenses.length} expenses');

    for (final expense in loadedExpenses) {
      debugPrint(
        'Expense: ${expense.title} | '
        '₹${expense.amount} | '
        '${expense.category}',
      );
    }

    setState(() {
      expenses = loadedExpenses;
    });
  }

  Future<void> _addExpense() async {
    final result = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );

    if (result == null) return;

    await ExpenseService.addExpense(result);

    if (!mounted) return;

    _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(expenses: expenses),
      ExpensesScreen(expenses: expenses, onExpensesChanged: _loadExpenses),
      AnalyticsScreen(expenses: expenses),
      const InvestmentsScreen(),
      const AccountsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],

      floatingActionButton: (_selectedIndex == 0 || _selectedIndex == 1)
          ? FloatingActionButton(
              onPressed: _addExpense,
              child: const Icon(Icons.add),
            )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Investments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
