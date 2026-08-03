import 'package:hive/hive.dart';

part 'import_history.g.dart';

@HiveType(typeId: 6)
class ImportHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String source;

  @HiveField(2)
  final DateTime importedAt;

  @HiveField(3)
  final int totalTransactions;

  @HiveField(4)
  final int importedExpenses;

  @HiveField(5)
  final int reviewedTransactions;

  @HiveField(6)
  final int skippedTransactions;

  @HiveField(7)
  final int merchantRulesSaved;

  @HiveField(8)
  final double importedAmount;

  @HiveField(9)
  final String? fileName;

  @HiveField(10)
  final String? notes;

  ImportHistory({
    required this.id,
    required this.source,
    required this.importedAt,
    required this.totalTransactions,
    required this.importedExpenses,
    required this.reviewedTransactions,
    required this.skippedTransactions,
    required this.merchantRulesSaved,
    required this.importedAmount,
    this.fileName,
    this.notes,
  });
}
