import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';

import '../models/account.dart';
import '../models/expense.dart';
import '../models/import_history.dart';
import '../models/investment.dart';
import '../models/merchant_rule.dart';
import '../models/pending_transaction.dart';
import '../models/reviewed_transaction.dart';

import 'account_service.dart';
import 'expense_service.dart';
import 'import_history_service.dart';
import 'investment_service.dart';
import 'merchant_rule_service.dart';
import 'pending_transaction_service.dart';
import 'reviewed_transaction_service.dart';

class BackupService {
  static const int backupVersion = 1;

  // ------------------------------------------------------------
  // Export Backup
  // ------------------------------------------------------------

  static Future<String?> exportBackup() async {
    final now = DateTime.now();

    final fileName =
        'GuruPilot_Backup_'
        '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}.json';

    final bytes = buildBackupBytes();

    final path = await FilePicker.saveFile(
      dialogTitle: 'Save GuruPilot Backup',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: bytes,
    );

    return path;
  }

  // ------------------------------------------------------------
  // Build Backup
  // ------------------------------------------------------------

  static Map<String, dynamic> buildBackup() {
    return {
      'app': 'GuruPilot',
      'backupVersion': backupVersion,
      'createdAt': DateTime.now().toIso8601String(),

      'expenses': Hive.box<Expense>(
        ExpenseService.boxName,
      ).values.map(_expenseToJson).toList(),

      'investments': Hive.box<Investment>(
        InvestmentService.boxName,
      ).values.map(_investmentToJson).toList(),

      'merchantRules': Hive.box<MerchantRule>(
        MerchantRuleService.boxName,
      ).values.map(_merchantRuleToJson).toList(),

      'pendingTransactions': Hive.box<PendingTransaction>(
        PendingTransactionService.boxName,
      ).values.map(_pendingTransactionToJson).toList(),

      'accounts': Hive.box<Account>(
        AccountService.boxName,
      ).values.map(_accountToJson).toList(),

      'reviewedTransactions': Hive.box<ReviewedTransaction>(
        ReviewedTransactionService.boxName,
      ).values.map(_reviewedTransactionToJson).toList(),

      'importHistory': Hive.box<ImportHistory>(
        ImportHistoryService.boxName,
      ).values.map(_importHistoryToJson).toList(),
    };
  }

  static String buildBackupJson() {
    const encoder = JsonEncoder.withIndent('  ');

    return encoder.convert(buildBackup());
  }

  static Uint8List buildBackupBytes() {
    return Uint8List.fromList(utf8.encode(buildBackupJson()));
  }

  // ------------------------------------------------------------
  // Pick Backup File
  // ------------------------------------------------------------

  static Future<String?> pickBackupFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
      allowMultiple: false,
    );

    if (result == null) {
      return null;
    }

    final bytes = result.files.single.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw Exception('Unable to read the selected backup file.');
    }

    return utf8.decode(bytes);
  }

  // ------------------------------------------------------------
  // Restore Backup
  // ------------------------------------------------------------

  static Future<RestoreResult> restoreFromJson(String jsonText) async {
    final decoded = jsonDecode(jsonText);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid GuruPilot backup file.');
    }

    if (decoded['app'] != 'GuruPilot') {
      throw Exception('This is not a GuruPilot backup file.');
    }

    final version = decoded['backupVersion'];

    if (version != backupVersion) {
      throw Exception('Unsupported backup version: $version');
    }

    var restoredExpenses = 0;
    var restoredInvestments = 0;
    var restoredMerchantRules = 0;
    var restoredPendingTransactions = 0;
    var restoredAccounts = 0;
    var restoredReviewedTransactions = 0;
    var restoredImportHistory = 0;

    final expenseBox = Hive.box<Expense>(ExpenseService.boxName);

    final investmentBox = Hive.box<Investment>(InvestmentService.boxName);

    final pendingBox = Hive.box<PendingTransaction>(
      PendingTransactionService.boxName,
    );

    final accountBox = Hive.box<Account>(AccountService.boxName);

    // ----------------------------------------------------------
    // Expenses
    // ----------------------------------------------------------

    final expenses = _readList(decoded, 'expenses');

    for (final entry in expenses) {
      final expense = _expenseFromJson(entry);

      final transactionId = expense.transactionId?.trim();

      final key = transactionId != null && transactionId.isNotEmpty
          ? transactionId
          : 'expense-'
                '${expense.date.microsecondsSinceEpoch}-'
                '${expense.amount}-'
                '${expense.title.hashCode}';

      await expenseBox.put(key, expense);

      restoredExpenses++;
    }

    // ----------------------------------------------------------
    // Investments
    // ----------------------------------------------------------

    final investments = _readList(decoded, 'investments');

    for (final entry in investments) {
      final investment = _investmentFromJson(entry);

      await investmentBox.add(investment);

      restoredInvestments++;
    }

    // ----------------------------------------------------------
    // Merchant Rules
    // ----------------------------------------------------------

    final merchantRules = _readList(decoded, 'merchantRules');

    for (final entry in merchantRules) {
      final rule = _merchantRuleFromJson(entry);

      await MerchantRuleService.saveRule(
        merchantName: rule.merchantName,
        category: rule.category,
        person: rule.person,
        paymentMethod: rule.paymentMethod,
      );

      restoredMerchantRules++;
    }

    // ----------------------------------------------------------
    // Pending Transactions
    // ----------------------------------------------------------

    final pendingTransactions = _readList(decoded, 'pendingTransactions');

    for (final entry in pendingTransactions) {
      final pending = _pendingTransactionFromJson(entry);

      await pendingBox.add(pending);

      restoredPendingTransactions++;
    }

    // ----------------------------------------------------------
    // Accounts
    // ----------------------------------------------------------

    final accounts = _readList(decoded, 'accounts');

    for (final entry in accounts) {
      final account = _accountFromJson(entry);

      await accountBox.add(account);

      restoredAccounts++;
    }

    // ----------------------------------------------------------
    // Reviewed Transactions
    // ----------------------------------------------------------

    final reviewedTransactions = _readList(decoded, 'reviewedTransactions');

    for (final entry in reviewedTransactions) {
      final reviewed = _reviewedTransactionFromJson(entry);

      await ReviewedTransactionService.save(reviewed);

      restoredReviewedTransactions++;
    }

    // ----------------------------------------------------------
    // Import History
    // ----------------------------------------------------------

    final importHistory = _readList(decoded, 'importHistory');

    for (final entry in importHistory) {
      final history = _importHistoryFromJson(entry);

      await ImportHistoryService.save(history);

      restoredImportHistory++;
    }

    return RestoreResult(
      expenses: restoredExpenses,
      investments: restoredInvestments,
      merchantRules: restoredMerchantRules,
      pendingTransactions: restoredPendingTransactions,
      accounts: restoredAccounts,
      reviewedTransactions: restoredReviewedTransactions,
      importHistory: restoredImportHistory,
    );
  }

  // ------------------------------------------------------------
  // Read List Helper
  // ------------------------------------------------------------

  static List<Map<String, dynamic>> _readList(
    Map<String, dynamic> root,
    String key,
  ) {
    final value = root[key];

    if (value == null) {
      return [];
    }

    if (value is! List) {
      throw Exception('Invalid backup section: $key');
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ------------------------------------------------------------
  // Expense
  // ------------------------------------------------------------

  static Map<String, dynamic> _expenseToJson(Expense item) {
    return {
      'title': item.title,
      'amount': item.amount,
      'category': item.category,
      'date': item.date.toIso8601String(),
      'merchant': item.merchant,
      'paymentMethod': item.paymentMethod,
      'source': item.source,
      'person': item.person,
      'transactionId': item.transactionId,
      'isCategorized': item.isCategorized,
      'notes': item.notes,
      'accountName': item.accountName,
    };
  }

  static Expense _expenseFromJson(Map<String, dynamic> json) {
    return Expense(
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      merchant: json['merchant'] as String?,
      paymentMethod: json['paymentMethod'] as String? ?? 'Unknown',
      source: json['source'] as String? ?? 'manual',
      person: json['person'] as String? ?? 'Shared',
      transactionId: json['transactionId'] as String?,
      isCategorized: json['isCategorized'] as bool? ?? true,
      notes: json['notes'] as String?,
      accountName: json['accountName'] as String?,
    );
  }

  // ------------------------------------------------------------
  // Investment
  // ------------------------------------------------------------

  static Map<String, dynamic> _investmentToJson(Investment item) {
    return {
      'title': item.title,
      'type': item.type,
      'investedAmount': item.investedAmount,
      'currentValue': item.currentValue,
      'date': item.date.toIso8601String(),
      'owner': item.owner,
      'notes': item.notes,
      'importId': item.importId,
      'source': item.source,
    };
  }

  static Investment _investmentFromJson(Map<String, dynamic> json) {
    return Investment(
      title: json['title'] as String,
      type: json['type'] as String,
      investedAmount: (json['investedAmount'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      owner: json['owner'] as String? ?? 'Guru',
      notes: json['notes'] as String? ?? '',
      importId: json['importId'] as String?,
      source: json['source'] as String? ?? 'manual',
    );
  }

  // ------------------------------------------------------------
  // Merchant Rule
  // ------------------------------------------------------------

  static Map<String, dynamic> _merchantRuleToJson(MerchantRule item) {
    return {
      'merchantName': item.merchantName,
      'category': item.category,
      'person': item.person,
      'paymentMethod': item.paymentMethod,
      'updatedAt': item.updatedAt.toIso8601String(),
    };
  }

  static MerchantRule _merchantRuleFromJson(Map<String, dynamic> json) {
    return MerchantRule(
      merchantName: json['merchantName'] as String,
      category: json['category'] as String,
      person: json['person'] as String? ?? 'Shared',
      paymentMethod: json['paymentMethod'] as String? ?? 'UPI',
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  // ------------------------------------------------------------
  // Pending Transaction
  // ------------------------------------------------------------

  static Map<String, dynamic> _pendingTransactionToJson(
    PendingTransaction item,
  ) {
    return {
      'title': item.title,
      'amount': item.amount,
      'date': item.date.toIso8601String(),
      'merchant': item.merchant,
      'paymentMethod': item.paymentMethod,
      'transactionId': item.transactionId,
      'source': item.source,
      'suggestedCategory': item.suggestedCategory,
      'suggestedPerson': item.suggestedPerson,
      'isReviewed': item.isReviewed,
      'notes': item.notes,
    };
  }

  static PendingTransaction _pendingTransactionFromJson(
    Map<String, dynamic> json,
  ) {
    return PendingTransaction(
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      merchant: json['merchant'] as String,
      paymentMethod: json['paymentMethod'] as String? ?? 'UPI',
      transactionId: json['transactionId'] as String?,
      source: json['source'] as String? ?? 'bank_feed',
      suggestedCategory: json['suggestedCategory'] as String?,
      suggestedPerson: json['suggestedPerson'] as String?,
      isReviewed: json['isReviewed'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  // ------------------------------------------------------------
  // Account
  // ------------------------------------------------------------

  static Map<String, dynamic> _accountToJson(Account item) {
    return {
      'name': item.name,
      'type': item.type,
      'openingBalance': item.openingBalance,
      'currentBalance': item.currentBalance,
      'currency': item.currency,
      'isActive': item.isActive,
      'createdDate': item.createdDate.toIso8601String(),
      'notes': item.notes,
    };
  }

  static Account _accountFromJson(Map<String, dynamic> json) {
    return Account(
      name: json['name'] as String,
      type: json['type'] as String,
      openingBalance: (json['openingBalance'] as num).toDouble(),
      currentBalance: (json['currentBalance'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      isActive: json['isActive'] as bool? ?? true,
      createdDate: DateTime.parse(json['createdDate'] as String),
      notes: json['notes'] as String? ?? '',
    );
  }

  // ------------------------------------------------------------
  // Reviewed Transaction
  // ------------------------------------------------------------

  static Map<String, dynamic> _reviewedTransactionToJson(
    ReviewedTransaction item,
  ) {
    return {
      'transactionId': item.transactionId,
      'transactionType': item.transactionType,
      'merchant': item.merchant,
      'amount': item.amount,
      'transactionDate': item.transactionDate.toIso8601String(),
      'reviewedAt': item.reviewedAt.toIso8601String(),
      'source': item.source,
      'notes': item.notes,
    };
  }

  static ReviewedTransaction _reviewedTransactionFromJson(
    Map<String, dynamic> json,
  ) {
    return ReviewedTransaction(
      transactionId: json['transactionId'] as String,
      transactionType: json['transactionType'] as String,
      merchant: json['merchant'] as String,
      amount: (json['amount'] as num).toDouble(),
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      reviewedAt: DateTime.parse(json['reviewedAt'] as String),
      source: json['source'] as String? ?? 'backup_restore',
      notes: json['notes'] as String?,
    );
  }

  // ------------------------------------------------------------
  // Import History
  // ------------------------------------------------------------

  static Map<String, dynamic> _importHistoryToJson(ImportHistory item) {
    return {
      'id': item.id,
      'source': item.source,
      'importedAt': item.importedAt.toIso8601String(),
      'totalTransactions': item.totalTransactions,
      'importedExpenses': item.importedExpenses,
      'reviewedTransactions': item.reviewedTransactions,
      'skippedTransactions': item.skippedTransactions,
      'merchantRulesSaved': item.merchantRulesSaved,
      'importedAmount': item.importedAmount,
      'fileName': item.fileName,
      'notes': item.notes,
    };
  }

  static ImportHistory _importHistoryFromJson(Map<String, dynamic> json) {
    return ImportHistory(
      id: json['id'] as String,
      source: json['source'] as String,
      importedAt: DateTime.parse(json['importedAt'] as String),
      totalTransactions: (json['totalTransactions'] as num).toInt(),
      importedExpenses: (json['importedExpenses'] as num).toInt(),
      reviewedTransactions: (json['reviewedTransactions'] as num).toInt(),
      skippedTransactions: (json['skippedTransactions'] as num).toInt(),
      merchantRulesSaved: (json['merchantRulesSaved'] as num).toInt(),
      importedAmount: (json['importedAmount'] as num).toDouble(),
      fileName: json['fileName'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

// --------------------------------------------------------------
// Restore Result
// --------------------------------------------------------------

class RestoreResult {
  final int expenses;
  final int investments;
  final int merchantRules;
  final int pendingTransactions;
  final int accounts;
  final int reviewedTransactions;
  final int importHistory;

  const RestoreResult({
    required this.expenses,
    required this.investments,
    required this.merchantRules,
    required this.pendingTransactions,
    required this.accounts,
    required this.reviewedTransactions,
    required this.importHistory,
  });

  int get total {
    return expenses +
        investments +
        merchantRules +
        pendingTransactions +
        accounts +
        reviewedTransactions +
        importHistory;
  }
}
