import 'package:hive/hive.dart';

part 'investment.g.dart';

@HiveType(typeId: 1)
class Investment extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final double investedAmount;

  @HiveField(3)
  final double currentValue;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String owner;

  @HiveField(6)
  final String notes;

  @HiveField(7)
  final String? importId;

  @HiveField(8, defaultValue: 'manual')
  final String source;

  Investment({
    required this.title,
    required this.type,
    required this.investedAmount,
    required this.currentValue,
    required this.date,
    this.owner = 'Guru',
    this.notes = '',
    this.importId,
    this.source = 'manual',
  });

  Investment copyWith({
    String? title,
    String? type,
    double? investedAmount,
    double? currentValue,
    DateTime? date,
    String? owner,
    String? notes,
    String? importId,
    String? source,
  }) {
    return Investment(
      title: title ?? this.title,
      type: type ?? this.type,
      investedAmount: investedAmount ?? this.investedAmount,
      currentValue: currentValue ?? this.currentValue,
      date: date ?? this.date,
      owner: owner ?? this.owner,
      notes: notes ?? this.notes,
      importId: importId ?? this.importId,
      source: source ?? this.source,
    );
  }
}
