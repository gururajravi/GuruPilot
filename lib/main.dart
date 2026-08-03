import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/historical_expenses_2026.dart';
import 'models/account.dart';
import 'models/expense.dart';
import 'models/investment.dart';
import 'models/merchant_rule.dart';
import 'models/pending_transaction.dart';
import 'models/reviewed_transaction.dart';

import 'screens/home_screen.dart';

import 'services/account_service.dart';
import 'services/expense_service.dart';
import 'services/investment_service.dart';
import 'services/merchant_rule_service.dart';
import 'services/pending_transaction_service.dart';
import 'services/reviewed_transaction_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Expense
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ExpenseAdapter());
  }

  // Investment
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(InvestmentAdapter());
  }

  // Merchant Rules
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(MerchantRuleAdapter());
  }

  // Pending Transactions
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(PendingTransactionAdapter());
  }

  // Accounts
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(AccountAdapter());
  }

  // Reviewed Transactions
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(ReviewedTransactionAdapter());
  }

  //--------------------------------------------------
  // Open Hive Boxes
  //--------------------------------------------------

  await Hive.openBox<Expense>(ExpenseService.boxName);

  await Hive.openBox<Investment>(InvestmentService.boxName);

  await Hive.openBox<MerchantRule>(MerchantRuleService.boxName);

  await Hive.openBox<PendingTransaction>(PendingTransactionService.boxName);

  await Hive.openBox<Account>(AccountService.boxName);

  await Hive.openBox<ReviewedTransaction>(ReviewedTransactionService.boxName);

  //--------------------------------------------------
  // Load Sample Historical Data
  //--------------------------------------------------

  final importedCount = await ExpenseService.importExpenses(
    buildHistoricalExpenses2026(),
  );

  final expenseBox = Hive.box<Expense>(ExpenseService.boxName);

  debugPrint('Historical expenses imported: $importedCount');

  debugPrint('Hive expense box name: ${expenseBox.name}');

  debugPrint('Hive expense box length: ${expenseBox.length}');

  debugPrint('Hive expense box keys: ${expenseBox.keys.toList()}');

  for (final expense in expenseBox.values) {
    debugPrint(
      'Loaded expense: '
      '${expense.title}, '
      '₹${expense.amount}, '
      '${expense.category}, '
      '${expense.date}, '
      '${expense.source}, '
      '${expense.transactionId}',
    );
  }

  runApp(const GuruPilotApp());
}

class GuruPilotApp extends StatelessWidget {
  const GuruPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GuruPilot',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
