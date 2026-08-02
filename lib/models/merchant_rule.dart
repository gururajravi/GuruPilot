import 'package:hive/hive.dart';

part 'merchant_rule.g.dart';

@HiveType(typeId: 2)
class MerchantRule extends HiveObject {
  @HiveField(0)
  final String merchantName;

  @HiveField(1)
  final String category;

  @HiveField(2)
  final String person;

  @HiveField(3)
  final String paymentMethod;

  @HiveField(4)
  final DateTime updatedAt;

  MerchantRule({
    required this.merchantName,
    required this.category,
    this.person = 'Shared',
    this.paymentMethod = 'UPI',
    required this.updatedAt,
  });

  MerchantRule copyWith({
    String? merchantName,
    String? category,
    String? person,
    String? paymentMethod,
    DateTime? updatedAt,
  }) {
    return MerchantRule(
      merchantName: merchantName ?? this.merchantName,
      category: category ?? this.category,
      person: person ?? this.person,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
