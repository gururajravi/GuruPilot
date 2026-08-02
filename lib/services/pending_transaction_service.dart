import 'package:hive/hive.dart';

import '../models/expense.dart';
import '../models/pending_transaction.dart';
import 'expense_service.dart';
import 'merchant_rule_service.dart';

class PendingTransactionService {
  static const String boxName = 'pending_transactions';

  static Box<PendingTransaction> get _box {
    return Hive.box<PendingTransaction>(boxName);
  }

  static List<PendingTransaction> getPendingTransactions() {
    final transactions = _box.values
        .where((transaction) => !transaction.isReviewed)
        .toList();

    transactions.sort((first, second) => second.date.compareTo(first.date));

    return transactions;
  }

  static bool _transactionExists(String? transactionId) {
    if (transactionId == null || transactionId.trim().isEmpty) {
      return false;
    }

    return _box.values.any(
      (transaction) => transaction.transactionId == transactionId,
    );
  }

  static Future<bool> addPendingTransaction(
    PendingTransaction transaction,
  ) async {
    if (_transactionExists(transaction.transactionId)) {
      return false;
    }

    final rule = MerchantRuleService.suggestRule(transaction.merchant);

    final enrichedTransaction = transaction.copyWith(
      suggestedCategory: rule?.category ?? transaction.suggestedCategory,
      suggestedPerson: rule?.person ?? transaction.suggestedPerson,
      paymentMethod: rule?.paymentMethod ?? transaction.paymentMethod,
    );

    await _box.add(enrichedTransaction);

    return true;
  }

  static Future<void> approveTransaction({
    required PendingTransaction transaction,
    required String category,
    required String person,
    required String paymentMethod,
    bool rememberMerchant = true,
  }) async {
    final expense = Expense(
      title: transaction.title,
      amount: transaction.amount,
      category: category,
      date: transaction.date,
      merchant: transaction.merchant,
      paymentMethod: paymentMethod,
      source: transaction.source,
      person: person,
      transactionId: transaction.transactionId,
      isCategorized: category != 'Uncategorized',
      notes: transaction.notes,
    );

    await ExpenseService.addExpense(expense);

    if (rememberMerchant && transaction.merchant.trim().isNotEmpty) {
      await MerchantRuleService.saveRule(
        merchantName: transaction.merchant,
        category: category,
        person: person,
        paymentMethod: paymentMethod,
      );
    }

    final key = transaction.key;

    if (key == null) {
      throw Exception('Pending transaction key was not found.');
    }

    final reviewedTransaction = transaction.copyWith(
      suggestedCategory: category,
      suggestedPerson: person,
      paymentMethod: paymentMethod,
      isReviewed: true,
    );

    await _box.put(key, reviewedTransaction);
  }

  static Future<void> deletePendingTransaction(
    PendingTransaction transaction,
  ) async {
    final key = transaction.key;

    if (key == null) {
      throw Exception('Pending transaction key was not found.');
    }

    await _box.delete(key);
  }

  static Future<void> clearPendingTransactions() async {
    await _box.clear();
  }
}
