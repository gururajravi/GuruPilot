import '../models/expense.dart';

class AnalyticsService {
  static double totalExpense(List<Expense> expenses) {
    return expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  static Map<String, double> categoryTotals(List<Expense> expenses) {
    final Map<String, double> totals = {};

    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return totals;
  }

  static double averageExpense(List<Expense> expenses) {
    if (expenses.isEmpty) return 0;

    return totalExpense(expenses) / expenses.length;
  }

  static Expense? highestExpense(List<Expense> expenses) {
    if (expenses.isEmpty) return null;

    return expenses.reduce(
      (first, second) => first.amount >= second.amount ? first : second,
    );
  }

  static String mostUsedCategory(List<Expense> expenses) {
    if (expenses.isEmpty) return "N/A";

    final counts = <String, int>{};

    for (final expense in expenses) {
      counts.update(expense.category, (value) => value + 1, ifAbsent: () => 1);
    }

    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}
