import 'import_transaction.dart';

enum ImportTransactionType { expense, transfer, income, refund, unknown }

class ImportReviewItem {
  final ImportTransaction transaction;

  final ImportTransactionType transactionType;

  final String category;

  final String person;

  final String paymentMethod;

  final bool shouldImport;

  final bool isDuplicate;

  final bool rememberMerchant;

  const ImportReviewItem({
    required this.transaction,
    this.transactionType = ImportTransactionType.unknown,
    this.category = 'Uncategorized',
    this.person = 'Shared',
    this.paymentMethod = 'UPI',
    this.shouldImport = true,
    this.isDuplicate = false,
    this.rememberMerchant = true,
  });

  ImportReviewItem copyWith({
    ImportTransaction? transaction,
    ImportTransactionType? transactionType,
    String? category,
    String? person,
    String? paymentMethod,
    bool? shouldImport,
    bool? isDuplicate,
    bool? rememberMerchant,
  }) {
    return ImportReviewItem(
      transaction: transaction ?? this.transaction,
      transactionType: transactionType ?? this.transactionType,
      category: category ?? this.category,
      person: person ?? this.person,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      shouldImport: shouldImport ?? this.shouldImport,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      rememberMerchant: rememberMerchant ?? this.rememberMerchant,
    );
  }
}
