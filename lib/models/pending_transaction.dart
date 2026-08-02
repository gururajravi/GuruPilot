import 'package:hive/hive.dart';

part 'pending_transaction.g.dart';

@HiveType(typeId: 3)
class PendingTransaction extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String merchant;

  @HiveField(4)
  final String paymentMethod;

  @HiveField(5)
  final String? transactionId;

  @HiveField(6)
  final String source;

  @HiveField(7)
  final String? suggestedCategory;

  @HiveField(8)
  final String? suggestedPerson;

  @HiveField(9)
  final bool isReviewed;

  @HiveField(10)
  final String? notes;

  PendingTransaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.merchant,
    this.paymentMethod = 'UPI',
    this.transactionId,
    this.source = 'bank_feed',
    this.suggestedCategory,
    this.suggestedPerson,
    this.isReviewed = false,
    this.notes,
  });

  PendingTransaction copyWith({
    String? title,
    double? amount,
    DateTime? date,
    String? merchant,
    String? paymentMethod,
    String? transactionId,
    String? source,
    String? suggestedCategory,
    String? suggestedPerson,
    bool? isReviewed,
    String? notes,
  }) {
    return PendingTransaction(
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      merchant: merchant ?? this.merchant,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      source: source ?? this.source,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      suggestedPerson: suggestedPerson ?? this.suggestedPerson,
      isReviewed: isReviewed ?? this.isReviewed,
      notes: notes ?? this.notes,
    );
  }
}
