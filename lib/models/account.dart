import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 4)
class Account extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final double openingBalance;

  @HiveField(3)
  final double currentBalance;

  @HiveField(4)
  final String currency;

  @HiveField(5)
  final bool isActive;

  @HiveField(6)
  final DateTime createdDate;

  @HiveField(7)
  final String notes;

  Account({
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.currentBalance,
    this.currency = 'INR',
    this.isActive = true,
    required this.createdDate,
    this.notes = '',
  });

  Account copyWith({
    String? name,
    String? type,
    double? openingBalance,
    double? currentBalance,
    String? currency,
    bool? isActive,
    DateTime? createdDate,
    String? notes,
  }) {
    return Account(
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdDate: createdDate ?? this.createdDate,
      notes: notes ?? this.notes,
    );
  }
}
