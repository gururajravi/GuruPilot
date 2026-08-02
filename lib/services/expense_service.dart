import 'package:hive/hive.dart';

import '../models/expense.dart';

class ExpenseService {
  static const String boxName = 'expenses';

  static Box<Expense> get _box => Hive.box<Expense>(boxName);

  static Future<void> addExpense(Expense expense) async {
    await _box.add(expense);
  }

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

  static Future<void> deleteExpense(Expense expense) async {
    final key = expense.key;

    if (key == null) {
      throw Exception('Expense key was not found.');
    }

    await _box.delete(key);
  }

  static List<Expense> getExpenses() {
    return _box.values.toList();
  }

  static double get totalExpense {
    return _box.values.fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  static Future<int> importExpenses(Iterable<Expense> expenses) async {
    final existingTransactionIds = _box.values
        .map((expense) => expense.transactionId)
        .whereType<String>()
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

  static Future<void> clearExpenses() async {
    await _box.clear();
  }
}
