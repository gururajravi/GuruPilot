import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/historical_expenses_2026.dart';

import 'models/account.dart';
import 'models/expense.dart';
import 'models/import_history.dart';
import 'models/investment.dart';
import 'models/merchant_rule.dart';
import 'models/pending_transaction.dart';
import 'models/reviewed_transaction.dart';

import 'screens/home_screen.dart';

import 'services/account_service.dart';
import 'services/expense_service.dart';
import 'services/import_history_service.dart';
import 'services/investment_service.dart';
import 'services/merchant_rule_service.dart';
import 'services/pending_transaction_service.dart';
import 'services/reviewed_transaction_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  //--------------------------------------------------------
  // Register Hive Adapters
  //--------------------------------------------------------

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ExpenseAdapter());
  }

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(InvestmentAdapter());
  }

  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(MerchantRuleAdapter());
  }

  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(PendingTransactionAdapter());
  }

  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(AccountAdapter());
  }

  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(ReviewedTransactionAdapter());
  }

  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(ImportHistoryAdapter());
  }

  //--------------------------------------------------------
  // Open Hive Boxes
  //--------------------------------------------------------

  await Hive.openBox<Expense>(ExpenseService.boxName);

  await Hive.openBox<Investment>(InvestmentService.boxName);

  await Hive.openBox<MerchantRule>(MerchantRuleService.boxName);

  await Hive.openBox<PendingTransaction>(PendingTransactionService.boxName);

  await Hive.openBox<Account>(AccountService.boxName);

  await Hive.openBox<ReviewedTransaction>(ReviewedTransactionService.boxName);

  await Hive.openBox<ImportHistory>(ImportHistoryService.boxName);

  //--------------------------------------------------------
  // Load Sample Data (only if expense box is empty)
  //--------------------------------------------------------

  final expenseBox = Hive.box<Expense>(ExpenseService.boxName);

  if (expenseBox.isEmpty) {
    final importedCount = await ExpenseService.importExpenses(
      buildHistoricalExpenses2026(),
    );

    debugPrint(
      'Historical expenses imported: '
      '$importedCount',
    );
  }

  //--------------------------------------------------------
  // Debug Logs
  //--------------------------------------------------------

  debugPrint('Expense count : ${expenseBox.length}');

  debugPrint(
    'Merchant rules : '
    '${Hive.box<MerchantRule>(MerchantRuleService.boxName).length}',
  );

  debugPrint(
    'Accounts : '
    '${Hive.box<Account>(AccountService.boxName).length}',
  );

  debugPrint(
    'Reviewed Transactions : '
    '${Hive.box<ReviewedTransaction>(ReviewedTransactionService.boxName).length}',
  );

  debugPrint(
    'Import History : '
    '${Hive.box<ImportHistory>(ImportHistoryService.boxName).length}',
  );

  runApp(const GuruPilotApp());
}

class GuruPilotApp extends StatelessWidget {
  const GuruPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuruPilot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const HomeScreen(),
    );
  }
}
