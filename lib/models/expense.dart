import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String? merchant;

  @HiveField(5, defaultValue: 'Unknown')
  final String paymentMethod;

  @HiveField(6, defaultValue: 'manual')
  final String source;

  @HiveField(7, defaultValue: 'Shared')
  final String person;

  @HiveField(8)
  final String? transactionId;

  @HiveField(9, defaultValue: true)
  final bool isCategorized;

  @HiveField(10)
  final String? notes;

  @HiveField(11)
  final int? accountKey;

  @HiveField(12)
  final String? accountName;

  Expense({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.merchant,
    this.paymentMethod = 'Unknown',
    this.source = 'manual',
    this.person = 'Shared',
    this.transactionId,
    this.isCategorized = true,
    this.notes,
    this.accountKey,
    this.accountName,
  });

  Expense copyWith({
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? merchant,
    String? paymentMethod,
    String? source,
    String? person,
    String? transactionId,
    bool? isCategorized,
    String? notes,
    int? accountKey,
    String? accountName,
  }) {
    return Expense(
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      merchant: merchant ?? this.merchant,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      source: source ?? this.source,
      person: person ?? this.person,
      transactionId: transactionId ?? this.transactionId,
      isCategorized: isCategorized ?? this.isCategorized,
      notes: notes ?? this.notes,
      accountKey: accountKey ?? this.accountKey,
      accountName: accountName ?? this.accountName,
    );
  }
}
