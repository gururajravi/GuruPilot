import 'package:hive/hive.dart';

import '../models/expense.dart';

class ExpenseService {
  static const String boxName = 'expenses';

  // Keep this untyped because the existing Hive box was created
  // and is currently used as Box<dynamic>.
  static Box get _box => Hive.box(boxName);

  // --------------------------------------------------------
  // Add Expense
  // --------------------------------------------------------

  static Future<void> addExpense(Expense expense) async {
    await _box.add(expense);
  }

  // --------------------------------------------------------
  // Update Expense
  // --------------------------------------------------------

  static Future<void> updateExpense(
    Expense existingExpense,
    Expense updatedExpense,
  ) async {
    final key = existingExpense.key;

    if (key == null) {
      throw Exception('Expense key was not found.');
    }

    await _box.put(key, updatedExpense);
  }

  // --------------------------------------------------------
  // Delete Expense
  // --------------------------------------------------------

  static Future<void> deleteExpense(Expense expense) async {
    final key = expense.key;

    if (key == null) {
      throw Exception('Expense key was not found.');
    }

    await _box.delete(key);
  }

  // --------------------------------------------------------
  // Get Expenses
  // --------------------------------------------------------

  static List<Expense> getExpenses() {
    return _box.values.whereType<Expense>().toList();
  }

  // --------------------------------------------------------
  // Total Expenses
  // --------------------------------------------------------

  static double get totalExpense {
    return _box.values.whereType<Expense>().fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
  }

  // --------------------------------------------------------
  // Import Expenses
  // --------------------------------------------------------

  static Future<int> importExpenses(Iterable<Expense> expenses) async {
    final existingTransactionIds = _box.values
        .whereType<Expense>()
        .map((expense) => expense.transactionId)
        .whereType<String>()
        .where((transactionId) => transactionId.trim().isNotEmpty)
        .toSet();

    final newExpenses = expenses.where((expense) {
      final transactionId = expense.transactionId;

      if (transactionId == null || transactionId.trim().isEmpty) {
        return true;
      }

      return !existingTransactionIds.contains(transactionId);
    }).toList();

    if (newExpenses.isEmpty) {
      return 0;
    }

    await _box.addAll(newExpenses);

    return newExpenses.length;
  }

  // --------------------------------------------------------
  // Clear Expenses
  // --------------------------------------------------------

  static Future<void> clearExpenses() async {
    await _box.clear();
  }
}
