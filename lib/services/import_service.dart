import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import '../models/expense.dart';
import '../models/import_history.dart';
import '../models/import_review_item.dart';
import '../models/import_transaction.dart';
import '../models/reviewed_transaction.dart';

import 'ai_learning_service.dart';
import 'expense_service.dart';
import 'import_history_service.dart';
import 'merchant_rule_service.dart';
import 'reviewed_transaction_service.dart';

class ImportService {
  static List<ImportTransaction> importedTransactions = [];

  // ------------------------------------------------------------
  // Basic Import Statistics
  // ------------------------------------------------------------

  static void clear() {
    importedTransactions.clear();
  }

  static int get totalTransactions {
    return importedTransactions.length;
  }

  static int get debitCount {
    return importedTransactions
        .where((transaction) => transaction.isDebit)
        .length;
  }

  static int get creditCount {
    return importedTransactions
        .where((transaction) => transaction.isCredit)
        .length;
  }

  static double get totalDebits {
    return importedTransactions
        .where((transaction) => transaction.isDebit)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  }

  static double get totalCredits {
    return importedTransactions
        .where((transaction) => transaction.isCredit)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  }

  // ------------------------------------------------------------
  // Pick PhonePe Excel
  // ------------------------------------------------------------

  static Future<List<ImportTransaction>?> pickAndParsePhonePeExcel() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
      allowMultiple: false,
    );

    if (result == null) {
      return null;
    }

    final file = result.files.single;
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw Exception('Unable to read the selected Excel file.');
    }

    return parsePhonePeExcel(bytes);
  }

  // ------------------------------------------------------------
  // Parse PhonePe Excel
  // ------------------------------------------------------------

  static List<ImportTransaction> parsePhonePeExcel(Uint8List bytes) {
    final workbook = Excel.decodeBytes(bytes);

    if (workbook.tables.isEmpty) {
      throw Exception('The Excel file does not contain any sheets.');
    }

    final sheet = workbook.tables.values.first;

    if (sheet.rows.isEmpty) {
      throw Exception('The Excel sheet is empty.');
    }

    final transactions = <ImportTransaction>[];

    for (var rowIndex = 0; rowIndex < sheet.rows.length; rowIndex++) {
      final row = sheet.rows[rowIndex];

      final dateText = _cellText(row, 0);
      final detailsText = _cellText(row, 1);
      final typeText = _cellText(row, 2);
      final amount = _cellNumber(row, 3);

      final normalizedType = typeText.trim().toLowerCase();

      final isTransactionRow =
          dateText.isNotEmpty &&
          detailsText.isNotEmpty &&
          (normalizedType == 'debit' || normalizedType == 'credit') &&
          amount != null;

      if (!isTransactionRow) {
        continue;
      }

      final nextRow = rowIndex + 1 < sheet.rows.length
          ? sheet.rows[rowIndex + 1]
          : null;

      final accountRow = rowIndex + 2 < sheet.rows.length
          ? sheet.rows[rowIndex + 2]
          : null;

      final utrText = nextRow == null ? '' : _cellText(nextRow, 1);

      final accountText = accountRow == null ? '' : _cellText(accountRow, 1);

      final parsedDate = _parsePhonePeDate(dateText);

      final transactionId = _extractTransactionId(detailsText);

      final merchant = _extractMerchant(detailsText);

      final utr = _extractUtr(utrText);

      final account = _extractAccount(accountText);

      if (parsedDate == null || transactionId.isEmpty) {
        continue;
      }

      transactions.add(
        ImportTransaction(
          date: parsedDate,
          merchant: merchant.isEmpty ? 'Unknown Merchant' : merchant,
          amount: amount,
          isCredit: normalizedType == 'credit',
          transactionId: transactionId,
          utr: utr.isEmpty ? null : utr,
          paymentMethod: 'PhonePe',
          account: account.isEmpty ? null : account,
          description: detailsText,
        ),
      );
    }

    // Remove duplicates inside the Excel itself.
    final uniqueTransactions = <String, ImportTransaction>{};

    for (final transaction in transactions) {
      uniqueTransactions[transaction.transactionId] = transaction;
    }

    importedTransactions = uniqueTransactions.values.toList()
      ..sort((first, second) => second.date.compareTo(first.date));

    return List<ImportTransaction>.unmodifiable(importedTransactions);
  }

  // ------------------------------------------------------------
  // Smart Sync / Build Review Items
  // ------------------------------------------------------------

  static List<ImportReviewItem> buildReviewItems() {
    final existingTransactionIds = ExpenseService.getExpenses()
        .map((expense) => expense.transactionId)
        .whereType<String>()
        .map((transactionId) => transactionId.trim())
        .where((transactionId) => transactionId.isNotEmpty)
        .toSet();

    final reviewedTransactionIds =
        ReviewedTransactionService.getReviewedTransactionIds();

    final reviewItems = <ImportReviewItem>[];

    for (final transaction in importedTransactions) {
      final transactionId = transaction.transactionId.trim();

      if (transactionId.isEmpty) {
        continue;
      }

      // ----------------------------------------------------------
      // Already reviewed transfer/income/refund?
      // Never ask again.
      // ----------------------------------------------------------

      if (reviewedTransactionIds.contains(transactionId)) {
        continue;
      }

      final isDuplicate = existingTransactionIds.contains(transactionId);

      // ----------------------------------------------------------
      // Credits -> Income
      // ----------------------------------------------------------

      if (transaction.isCredit) {
        reviewItems.add(
          ImportReviewItem(
            transaction: transaction,
            transactionType: ImportTransactionType.income,
            category: 'Uncategorized',
            person: 'Shared',
            paymentMethod: 'UPI',
            shouldImport: false,
            isDuplicate: isDuplicate,
            rememberMerchant: false,
            aiSuggestion: null,
          ),
        );

        continue;
      }

      // ----------------------------------------------------------
      // Refund Detection
      // ----------------------------------------------------------

      if (_looksLikeRefund(transaction)) {
        reviewItems.add(
          ImportReviewItem(
            transaction: transaction,
            transactionType: ImportTransactionType.refund,
            category: 'Uncategorized',
            person: 'Shared',
            paymentMethod: 'UPI',
            shouldImport: false,
            isDuplicate: isDuplicate,
            rememberMerchant: false,
            aiSuggestion: null,
          ),
        );

        continue;
      }

      // ----------------------------------------------------------
      // Person-to-person Transfer Detection
      // ----------------------------------------------------------

      if (_looksLikePersonTransfer(transaction)) {
        reviewItems.add(
          ImportReviewItem(
            transaction: transaction,
            transactionType: ImportTransactionType.transfer,
            category: 'Uncategorized',
            person: 'Shared',
            paymentMethod: 'UPI',
            shouldImport: false,
            isDuplicate: isDuplicate,
            rememberMerchant: false,
            aiSuggestion: null,
          ),
        );

        continue;
      }

      // ----------------------------------------------------------
      // AI Suggestion
      // ----------------------------------------------------------

      final aiSuggestion = AiLearningService.suggest(transaction.merchant);

      // ----------------------------------------------------------
      // Existing exact/saved merchant rule
      // ----------------------------------------------------------

      final merchantRule = MerchantRuleService.suggestRule(
        transaction.merchant,
      );

      if (merchantRule != null) {
        reviewItems.add(
          ImportReviewItem(
            transaction: transaction,
            transactionType: ImportTransactionType.expense,
            category: merchantRule.category,
            person: merchantRule.person,
            paymentMethod: merchantRule.paymentMethod,
            shouldImport: !isDuplicate,
            isDuplicate: isDuplicate,
            rememberMerchant: true,
            aiSuggestion: aiSuggestion,
          ),
        );

        continue;
      }

      // ----------------------------------------------------------
      // AI suggestion without direct MerchantRule
      // ----------------------------------------------------------

      if (aiSuggestion != null) {
        reviewItems.add(
          ImportReviewItem(
            transaction: transaction,
            transactionType: ImportTransactionType.expense,
            category: aiSuggestion.category,
            person: aiSuggestion.person,
            paymentMethod: aiSuggestion.paymentMethod,
            shouldImport: !isDuplicate,
            isDuplicate: isDuplicate,
            rememberMerchant: true,
            aiSuggestion: aiSuggestion,
          ),
        );

        continue;
      }

      // ----------------------------------------------------------
      // Completely unknown merchant
      // ----------------------------------------------------------

      reviewItems.add(
        ImportReviewItem(
          transaction: transaction,
          transactionType: ImportTransactionType.expense,
          category: 'Uncategorized',
          person: 'Shared',
          paymentMethod: 'UPI',
          shouldImport: !isDuplicate,
          isDuplicate: isDuplicate,
          rememberMerchant: true,
          aiSuggestion: null,
        ),
      );
    }

    return reviewItems;
  }

  // ------------------------------------------------------------
  // Import Reviewed Transactions
  // ------------------------------------------------------------

  static Future<ImportResult> importReviewedExpenses(
    Iterable<ImportReviewItem> reviewItems,
  ) async {
    final items = reviewItems.toList();

    var importedCount = 0;
    var skippedCount = 0;
    var rulesSavedCount = 0;
    var reviewedCount = 0;
    var importedAmount = 0.0;

    final existingTransactionIds = ExpenseService.getExpenses()
        .map((expense) => expense.transactionId)
        .whereType<String>()
        .map((transactionId) => transactionId.trim())
        .where((transactionId) => transactionId.isNotEmpty)
        .toSet();

    for (final item in items) {
      final transaction = item.transaction;

      final transactionId = transaction.transactionId.trim();

      if (transactionId.isEmpty) {
        skippedCount++;
        continue;
      }

      if (item.isDuplicate) {
        skippedCount++;
        continue;
      }

      // ----------------------------------------------------------
      // Save reviewed Transfer / Income / Refund
      // ----------------------------------------------------------

      if (_isReviewedNonExpense(item.transactionType)) {
        await ReviewedTransactionService.save(
          ReviewedTransaction(
            transactionId: transactionId,
            transactionType: item.transactionType.name,
            merchant: transaction.merchant,
            amount: transaction.amount,
            transactionDate: transaction.date,
            reviewedAt: DateTime.now(),
            source: 'phonepe_import',
            notes: _buildReviewedNotes(transaction, item.transactionType),
          ),
        );

        reviewedCount++;
        continue;
      }

      // ----------------------------------------------------------
      // Validate expense
      // ----------------------------------------------------------

      final canImportExpense =
          item.shouldImport &&
          item.transactionType == ImportTransactionType.expense &&
          item.category != 'Uncategorized';

      if (!canImportExpense) {
        skippedCount++;
        continue;
      }

      // ----------------------------------------------------------
      // Duplicate check before saving
      // ----------------------------------------------------------

      if (existingTransactionIds.contains(transactionId)) {
        skippedCount++;
        continue;
      }

      // ----------------------------------------------------------
      // Create expense
      // ----------------------------------------------------------

      final expense = Expense(
        title: transaction.merchant,
        amount: transaction.amount,
        category: item.category,
        date: transaction.date,
        merchant: transaction.merchant,
        paymentMethod: item.paymentMethod,
        source: 'phonepe_import',
        person: item.person,
        transactionId: transactionId,
        isCategorized: true,
        notes: _buildImportNotes(transaction),
        accountName: transaction.account,
      );

      await ExpenseService.addExpense(expense);

      existingTransactionIds.add(transactionId);

      importedCount++;
      importedAmount += transaction.amount;

      // ----------------------------------------------------------
      // Merchant Learning
      // ----------------------------------------------------------

      if (item.rememberMerchant && transaction.merchant.trim().isNotEmpty) {
        await MerchantRuleService.saveRule(
          merchantName: transaction.merchant,
          category: item.category,
          person: item.person,
          paymentMethod: item.paymentMethod,
        );

        rulesSavedCount++;
      }
    }

    // ------------------------------------------------------------
    // Save Import History
    // ------------------------------------------------------------

    final completedAt = DateTime.now();

    final history = ImportHistory(
      id: 'phonepe-${completedAt.microsecondsSinceEpoch}',
      source: 'PhonePe',
      importedAt: completedAt,
      totalTransactions: importedTransactions.length,
      importedExpenses: importedCount,
      reviewedTransactions: reviewedCount,
      skippedTransactions: skippedCount,
      merchantRulesSaved: rulesSavedCount,
      importedAmount: importedAmount,
      fileName: null,
      notes: _buildHistoryNotes(
        importedCount: importedCount,
        reviewedCount: reviewedCount,
        skippedCount: skippedCount,
        rulesSavedCount: rulesSavedCount,
        importedAmount: importedAmount,
      ),
    );

    await ImportHistoryService.save(history);

    return ImportResult(
      importedCount: importedCount,
      skippedCount: skippedCount,
      rulesSavedCount: rulesSavedCount,
      reviewedCount: reviewedCount,
      importedAmount: importedAmount,
      historyId: history.id,
    );
  }

  // ------------------------------------------------------------
  // Reviewed Non-expense Helper
  // ------------------------------------------------------------

  static bool _isReviewedNonExpense(ImportTransactionType type) {
    return type == ImportTransactionType.transfer ||
        type == ImportTransactionType.income ||
        type == ImportTransactionType.refund;
  }

  // ------------------------------------------------------------
  // Expense Notes
  // ------------------------------------------------------------

  static String _buildImportNotes(ImportTransaction transaction) {
    final parts = <String>['Imported from PhonePe'];

    if (transaction.utr != null && transaction.utr!.trim().isNotEmpty) {
      parts.add('UTR: ${transaction.utr}');
    }

    if (transaction.account != null && transaction.account!.trim().isNotEmpty) {
      parts.add('Account: ${transaction.account}');
    }

    return parts.join(' • ');
  }

  // ------------------------------------------------------------
  // Reviewed Transaction Notes
  // ------------------------------------------------------------

  static String _buildReviewedNotes(
    ImportTransaction transaction,
    ImportTransactionType type,
  ) {
    final parts = <String>['Reviewed as ${type.name}', 'Imported from PhonePe'];

    if (transaction.utr != null && transaction.utr!.trim().isNotEmpty) {
      parts.add('UTR: ${transaction.utr}');
    }

    if (transaction.account != null && transaction.account!.trim().isNotEmpty) {
      parts.add('Account: ${transaction.account}');
    }

    return parts.join(' • ');
  }

  // ------------------------------------------------------------
  // Import History Notes
  // ------------------------------------------------------------

  static String _buildHistoryNotes({
    required int importedCount,
    required int reviewedCount,
    required int skippedCount,
    required int rulesSavedCount,
    required double importedAmount,
  }) {
    return 'Imported $importedCount expense'
        '${importedCount == 1 ? '' : 's'} '
        'worth ₹${importedAmount.toStringAsFixed(2)}, '
        'saved $reviewedCount reviewed transaction'
        '${reviewedCount == 1 ? '' : 's'}, '
        'skipped $skippedCount transaction'
        '${skippedCount == 1 ? '' : 's'}, '
        'and saved $rulesSavedCount merchant rule'
        '${rulesSavedCount == 1 ? '' : 's'}.';
  }

  // ------------------------------------------------------------
  // Person Transfer Detection
  // ------------------------------------------------------------

  static bool _looksLikePersonTransfer(ImportTransaction transaction) {
    final merchant = transaction.merchant.trim().toLowerCase();

    final description = transaction.description.toLowerCase();

    final containsMaskedNumber = RegExp(
      r'x{3,}\d{3,}',
      caseSensitive: false,
    ).hasMatch(merchant);

    final containsPhoneNumber = RegExp(r'\b\d{10}\b').hasMatch(merchant);

    final containsUpiHandle = RegExp(
      r'@[a-z0-9._-]+',
      caseSensitive: false,
    ).hasMatch(merchant);

    const personKeywords = <String>[
      'paid to mobile number',
      'sent to',
      'money sent',
      'person to person',
    ];

    final containsPersonKeyword = personKeywords.any(description.contains);

    return containsMaskedNumber ||
        containsPhoneNumber ||
        containsUpiHandle ||
        containsPersonKeyword;
  }

  // ------------------------------------------------------------
  // Refund Detection
  // ------------------------------------------------------------

  static bool _looksLikeRefund(ImportTransaction transaction) {
    final description = transaction.description.toLowerCase();

    return description.contains('refund') ||
        description.contains('reversal') ||
        description.contains('reversed');
  }

  // ------------------------------------------------------------
  // Excel Cell Text
  // ------------------------------------------------------------

  static String _cellText(List<Data?> row, int columnIndex) {
    if (columnIndex < 0 || columnIndex >= row.length) {
      return '';
    }

    final value = row[columnIndex]?.value;

    if (value == null) {
      return '';
    }

    switch (value) {
      case TextCellValue():
        return value.value.toString().trim();

      case IntCellValue():
        return value.value.toString();

      case DoubleCellValue():
        return value.value.toString();

      case DateCellValue():
        return value.asDateTimeLocal().toString();

      case DateTimeCellValue():
        return value.asDateTimeLocal().toString();

      case TimeCellValue():
        return value.asDuration().toString();

      case BoolCellValue():
        return value.value.toString();

      case FormulaCellValue():
        return value.formula.trim();
    }
  }

  // ------------------------------------------------------------
  // Excel Cell Number
  // ------------------------------------------------------------

  static double? _cellNumber(List<Data?> row, int columnIndex) {
    if (columnIndex < 0 || columnIndex >= row.length) {
      return null;
    }

    final value = row[columnIndex]?.value;

    if (value == null) {
      return null;
    }

    switch (value) {
      case DoubleCellValue():
        return value.value;

      case IntCellValue():
        return value.value.toDouble();

      case TextCellValue():
        return _parseAmount(value.value.toString());

      case FormulaCellValue():
        return _parseAmount(value.formula);

      default:
        return _parseAmount(value.toString());
    }
  }

  // ------------------------------------------------------------
  // Amount Parser
  // ------------------------------------------------------------

  static double? _parseAmount(String value) {
    final cleaned = value
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .replaceAll('INR', '')
        .trim();

    return double.tryParse(cleaned);
  }

  // ------------------------------------------------------------
  // PhonePe Date Parser
  // ------------------------------------------------------------

  static DateTime? _parsePhonePeDate(String value) {
    final normalized = value
        .replaceAll('\r\n', '\n')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final phonePeMatch = RegExp(
      r'^([A-Za-z]{3})\s+'
      r'(\d{1,2}),\s+'
      r'(\d{4})\s+'
      r'(\d{1,2}):'
      r'(\d{2})\s+'
      r'(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (phonePeMatch != null) {
      const months = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };

      final monthName = phonePeMatch.group(1)!.toLowerCase();

      final month = months[monthName];

      if (month == null) {
        return null;
      }

      final day = int.parse(phonePeMatch.group(2)!);

      final year = int.parse(phonePeMatch.group(3)!);

      var hour = int.parse(phonePeMatch.group(4)!);

      final minute = int.parse(phonePeMatch.group(5)!);

      final period = phonePeMatch.group(6)!.toUpperCase();

      if (period == 'PM' && hour != 12) {
        hour += 12;
      }

      if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return DateTime(year, month, day, hour, minute);
    }

    return DateTime.tryParse(normalized);
  }

  // ------------------------------------------------------------
  // Merchant Extraction
  // ------------------------------------------------------------

  static String _extractMerchant(String details) {
    final normalized = details.replaceAll('\r\n', '\n').trim();

    if (normalized.isEmpty) {
      return '';
    }

    final firstLine = normalized.split('\n').first.trim();

    return firstLine
        .replaceFirst(
          RegExp(
            r'^(Paid to|Received from|'
            r'Refund from|Payment to)\s+',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  // ------------------------------------------------------------
  // Transaction ID Extraction
  // ------------------------------------------------------------

  static String _extractTransactionId(String details) {
    final match = RegExp(
      r'Transaction\s*ID\s*:\s*'
      r'([A-Za-z0-9_-]+)',
      caseSensitive: false,
    ).firstMatch(details);

    return match?.group(1)?.trim() ?? '';
  }

  // ------------------------------------------------------------
  // UTR Extraction
  // ------------------------------------------------------------

  static String _extractUtr(String value) {
    final match = RegExp(
      r'UTR\s*(?:No)?\s*:\s*'
      r'([A-Za-z0-9_-]+)',
      caseSensitive: false,
    ).firstMatch(value);

    return match?.group(1)?.trim() ?? '';
  }

  // ------------------------------------------------------------
  // Account Extraction
  // ------------------------------------------------------------

  static String _extractAccount(String value) {
    return value
        .replaceFirst(
          RegExp(r'^(Debited from|Credited to)\s+', caseSensitive: false),
          '',
        )
        .trim();
  }
}

// --------------------------------------------------------------
// Import Result
// --------------------------------------------------------------

class ImportResult {
  final int importedCount;
  final int skippedCount;
  final int rulesSavedCount;
  final int reviewedCount;
  final double importedAmount;
  final String historyId;

  const ImportResult({
    required this.importedCount,
    required this.skippedCount,
    required this.rulesSavedCount,
    required this.reviewedCount,
    required this.importedAmount,
    required this.historyId,
  });
}
