import 'package:hive/hive.dart';

part 'reviewed_transaction.g.dart';

@HiveType(typeId: 5)
class ReviewedTransaction extends HiveObject {
  @HiveField(0)
  final String transactionId;

  @HiveField(1)
  final String transactionType;

  @HiveField(2)
  final String merchant;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final DateTime transactionDate;

  @HiveField(5)
  final DateTime reviewedAt;

  @HiveField(6)
  final String source;

  @HiveField(7)
  final String? notes;

  ReviewedTransaction({
    required this.transactionId,
    required this.transactionType,
    required this.merchant,
    required this.amount,
    required this.transactionDate,
    required this.reviewedAt,
    this.source = 'phonepe_import',
    this.notes,
  });

  ReviewedTransaction copyWith({
    String? transactionId,
    String? transactionType,
    String? merchant,
    double? amount,
    DateTime? transactionDate,
    DateTime? reviewedAt,
    String? source,
    String? notes,
  }) {
    return ReviewedTransaction(
      transactionId: transactionId ?? this.transactionId,
      transactionType: transactionType ?? this.transactionType,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      source: source ?? this.source,
      notes: notes ?? this.notes,
    );
  }
}
