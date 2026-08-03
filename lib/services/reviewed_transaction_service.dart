import 'package:hive/hive.dart';

import '../models/reviewed_transaction.dart';

class ReviewedTransactionService {
  static const String boxName = 'reviewed_transactions';

  static Box<ReviewedTransaction> get _box {
    return Hive.box<ReviewedTransaction>(boxName);
  }

  static List<ReviewedTransaction> getAll() {
    return _box.values.toList()
      ..sort((first, second) => second.reviewedAt.compareTo(first.reviewedAt));
  }

  static Set<String> getReviewedTransactionIds() {
    return _box.values
        .map((item) => item.transactionId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  static bool isReviewed(String transactionId) {
    final normalizedId = transactionId.trim();

    if (normalizedId.isEmpty) {
      return false;
    }

    return _box.containsKey(normalizedId);
  }

  static ReviewedTransaction? getByTransactionId(String transactionId) {
    final normalizedId = transactionId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    return _box.get(normalizedId);
  }

  static Future<void> save(ReviewedTransaction transaction) async {
    final normalizedId = transaction.transactionId.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError('Reviewed transaction ID cannot be empty.');
    }

    await _box.put(normalizedId, transaction);
  }

  static Future<void> delete(String transactionId) async {
    final normalizedId = transactionId.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    await _box.delete(normalizedId);
  }

  static Future<void> clear() async {
    await _box.clear();
  }
}
